### TL;DR

**Force gpsd to treat the GP‑02 as a plain NMEA‑0183 device (9600 baud) while leaving every other GPS free to auto‑detect.**

1. **Create a per‑device driver override** (`/dev/ttyS0:nmea0183`).
2. **Add a udev rule** that attaches that override automatically whenever the GP‑02’s USB‑to‑UART dongle appears.
3. **Restart gpsd** (or start it manually with the same override).

That stops gpsd from sending any UBX configuration packets, keeps the port at 9600 bps, and leaves the NEO‑F9T (or any other GPS) untouched.

Below is a step‑by‑step guide that works on the standard Raspberry‑Pi OS image used on the U‑Console CM4. Adjust paths if you run a different distro.

---

## 1. Identify the GP‑02’s USB‑Serial identifiers

Plug the board in, power it up, and run:

`udevadm info -a -n /dev/ttyS0 | grep '{idVendor}' -A2`

Typical output for a cheap CP210x‑style converter looks like:

```
looking at parent device '/devices/platform/soc/20201000.serial/tty/ttyS0':
    KERNEL=="ttyS0"
    SUBSYSTEM=="tty"    
    DRIVER=="serial8250" 
looking at parent device '/devices/platform/soc/20201000.serial':
    ATTRS{idVendor}=="10c4"
    ATTRS{idProduct}=="ea60"
```

Take note of **idVendor** and **idProduct** (e.g. `10c4` / `ea60`). Those values uniquely identify the GP‑02’s USB‑to‑UART bridge.

> **Why we need them:**  
> The udev rule we’ll create matches on these IDs, so the driver override is applied **only** to this board. Any other GPS (NEO‑F9T, etc.) will keep the normal auto‑probe behaviour.

---

## 2. Write a udev rule that forces the NMEA driver

Create a new file `/etc/udev/rules.d/99-gp02-nmea.rules` with root privileges:

`sudo nano /etc/udev/rules.d/99-gp02-nmea.rules`

Paste the following (replace the vendor/product IDs with the ones you found):

`# GP‑02 off‑brand GPS – force gpsd to use the generic NMEA driver ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", \ ENV{GPSD_OPTIONS}="nmea0183", \ SYMLINK+="gps_gp02", \ ENV{ID_SERIAL_SHORT}="GP02"`

Explanation:

|Part|What it does|
|---|---|
|`ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60"`|Matches only the GP‑02’s USB‑serial chip.|
|`ENV{GPSD_OPTIONS}="nmea0183"`|Tells gpsd (via its udev integration) to attach the **nmea0183** driver to the device.|
|`SYMLINK+="gps_gp02"`|Gives you a stable alias (`/dev/gps_gp02`) you can reference in `/etc/default/gpsd` if you prefer.|
|`ENV{ID_SERIAL_SHORT}`|Optional – helps you spot the device with `udevadm monitor`.|

Save and exit.

Reload udev so the rule takes effect immediately:

`sudo udevadm control --reload-rules && sudo udevadm trigger`

You should now see the symlink appear:

`ls -l /dev/gps_gp02 # lrwxrwxrwx 1 root root 7 Oct 4 12:34 /dev/gps_gp02 -> ttyS0`

---

## 3. Tell gpsd to honour the udev‑provided driver hint

On most Pi images gpsd reads the environment variable `GPSD_OPTIONS` that udev sets on the device node. All you need to do is **restart gpsd** so it picks up the new rule.

`sudo systemctl restart gpsd`

You can verify the driver assignment with:

`gpsctl -l   # list known devices and drivers`

You should see something like:

```
/dev/ttyS0 (gps_gp02)   driver=nmea0183   baud=9600
```

If you don’t see the driver column, run gpsd in debug mode for a quick check:

`sudo gpsd -N -D2 -F /var/run/gpsd.sock /dev/ttyS0 &`

Look for a line similar to:

```
gpsd[12345]: device /dev/ttyS0: driver nmea0183 (forced by udev)
```

---

## 4. Keep other GPSes untouched

Because the udev rule matches **only** the GP‑02’s vendor/product pair, any other serial GPS (e.g. a NEO‑F9T on a different USB‑serial adapter) will be handled by gpsd’s normal auto‑probe logic. No extra configuration is required.

If you later plug a second GP‑02 into a different port, the rule will still fire because it matches the USB IDs, not the tty name. The symlink (`/dev/gps_gp02`) will point to the newest matching device, but you can also give each instance a unique alias by adding a `%k` token (kernel name) to the SYMLINK line, e.g.:

`SYMLINK+="gps_gp02_%k"`

That would create `/dev/gps_gp02_ttyS0`, `/dev/gps_gp02_ttyS1`, etc., letting you address each board individually.

---

## 5. Optional: Hard‑code the driver in `/etc/default/gpsd` (if you prefer not to rely on udev)

If you’d rather avoid udev entirely, you can edit the static gpsd config file. On Raspberry‑Pi OS it lives at `/etc/default/gpsd`.

`sudo nano /etc/default/gpsd`

Replace (or add) the `DEVICES` line with the driver suffix:

`DEVICES="/dev/ttyS0:nmea0183"`

Leave everything else untouched, then restart:

`sudo systemctl restart gpsd`

**Caveat:** This method forces the NMEA driver **every time** `/dev/ttyS0` appears, even if you later plug a different GPS into that same UART. That’s why the udev approach is usually preferred for a mixed‑hardware setup.

---

## 6. Verify the fix – end‑to‑end test

1. **Power‑cycle** the board (or unplug/replug the USB‑serial dongle).

2. Run a client, e.g.:

   `cgps -s`

3. You should see clean NMEA sentences (`$GPGGA`, `$GPRMC`, …) at **9600 bps** and the “ANTENNA OPEN” line appearing exactly as before. No garbled data, no UBX packets, and the client stays connected indefinitely.

4. Plug in your NEO‑F9T (or any other GPS) on a different UART/USB port. Start `cgps` again pointing at that device (or just let gpsd auto‑detect). It should work exactly as it did before—no loss of functionality.


---

## 7. Quick cheat‑sheet for future changes

| Goal                                                | Action                                                                                                                                                         |
|-----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Force NMEA on GP‑02 only**                        | Add/keep the udev rule (`99-gp02-nmea.rules`).                                                                                                                 |
| **Re‑enable auto‑detect for a device**              | Remove the rule line that matches its vendor/product, reload udev, restart gpsd.                                                                               |
| **Force a different baud rate** (e.g. 38400)        | Append `:baud=38400` to the device spec in `/etc/default/gpsd` **or** add `OPTIONS="baud=38400"` in the udev rule (`ENV{GPSD_OPTIONS}="nmea0183,baud=38400"`). |
| **Temporarily test without restarting the service** | Stop gpsd, run it manually with the explicit driver: `sudo gpsd -N -n -F /var/run/gpsd.sock /dev/ttyS0:nmea0183`                                               |
| **Debug why gpsd is re‑configuring a port**         | Run `sudo gpsd -D5 -F /var/run/gpsd.sock /dev/ttyS0` and watch the verbose log for “sending UBX…”.                                                             |

---

## 8. What if you don’t have root access to edit udev or `/etc/default/gpsd`?

You can still launch gpsd **per‑session** with the driver forced on the command line:

`gpsd -N -n -F /tmp/gpsd.sock /dev/ttyS0:nmea0183 & cgps -s -p /tmp/gpsd.sock`

That spawns a private gpsd instance that only talks to the GP‑02, leaving the system‑wide gpsd untouched. It’s handy for testing or for containers where you can’t modify host files.

---

## 9. Summary of the whole workflow

1. **Detect** the USB‑serial IDs of the GP‑02.
2. **Create** a udev rule that adds `ENV{GPSD_OPTIONS}="nmea0183"` (and optionally a stable symlink).
3. **Reload** udev and **restart** gpsd.
4. **Confirm** with `gpsctl -l` or a debug run that the driver is `nmea0183`.
5. **Test** with any gps client – you should now get clean 9600 bps NMEA data, and the “ANTENNA OPEN” line remains intact.
6. **Leave** all other GPS devices alone; they will continue to be auto‑detected and can use ublox, rtcm, etc., as before.

With those steps you get a robust, per‑device configuration that survives power cycles, hot‑plugs, and future firmware upgrades of the U‑Console. Happy tracking!