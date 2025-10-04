# Clockwork PI uConsole Setup

This is my aggregation of widespread wisdom from others' experiences getting their uConsoles up and going, as well as special attention for setting up the following things:

- Hardware RTC support
- Hardware GPS support
- Hardware RTL-SDR support
- `gpsd` running fulltime
- `chrony` time sync using NMEA and PPS for microsecond accuracy
- ADS-B (1090) monitoring

---

## Assumptions

The following assumptions are made in this document, and in the shellscript:

1. You are using the same (or strictly compatible) hardware setup as me (detailed below)
2. You are using the same base image as me (also detailed below)

If you're using a different base image, your mileage may vary. If you're using a different hardware setup, then you'll probably experience some speed bumps along the way (e.g. device path naming, etc.)

## Use It

```aiignore
sudo bash -c "$(wget -nv -O - https://github.com/storskegg/uconsole/raw/master/setup.sh)"
```

## My Hardware Setup

- [Clockwork PI uConsole CM4](https://www.clockworkpi.com/product-page/uconsole-kit-rpi-cm4-lite) w/ 4104000 CM4 (plans to upgrade to 4108000; CM5 will require special thermal considerations, so I don't think we'll see official support any time soon)
- [RTL-SDR+GPS+LoRa Expansion Board](https://hackergadgets.com/products/uconsole-rtl-sdr-lora-gps-rtc-usb-hub-all-in-one-extension-board)
- `instert microsd here`
- 2x NiteCore 18650 3500mAh Li-Ion
- Various antennas

## My Software Setup

### Base Image

Rather than the stock base image for the uConsole, I've opted to use Rex's "Bookworm" distro. It comes with a lot of things already set up for SDR work, and is future-looking for official CM5 support on the uConsole.

In the linked discussion, Rex includes a GitHub link, should you want to compile the image yourself.

### Performance

- 2GHz Overclocking + 6V Overvolting; On my uConsole, I don't see over 48°C with passive cooling with this setup.
- Increased charging rates

### Time

Some of what I do in the field requires accurate time. I love that the expansion board comes with an RTC, and even better is being able to leverage the PPS signal off the GPS for time accuracy in the microseconds range, vs milliseconds. Even better, I don't need an internet connection to sync the time. All I need is 4 satelites in view:

1. X
2. Y
3. Z
4. Time

### RTL-SDR and ADS-B

SDR++ is pre-installed in the base image, above, and that's all great and dandy. I plan on using this device for monitoring ADS-B (1090 MHz), and my setup reflects that with full-time monitoring. (It can be disabled for other SDR use.)

### LoRa and Meshtastic

While I generally have little interest in Meshtastic (kind of a neat toy), I have made extensinve use of LoRa in the past for everything from sensor networks to troposcatter experimentation to an obscenely secure garagedoor opener. This functionality is just one more toy in the playground.

## Notes on CM5

While I love hacking things, I have no plans to make destructive changes to the uConsole's chassis/enclosure to accommodate the CM5 module. I know a few people have carved the way on this, report (mixed) successes, etc, but for my personal uses of this device, I will wait until there's official CM5 support to make the upgrade.

## TODO

At some point, I may convert this to a deb package so that `apt` can do all the heavy lifting for me.

## List of References

- [Bookworm Distro](https://forum.clockworkpi.com/t/bookworm-6-6-y-for-the-uconsole-and-devterm/13235)
- https://gist.github.com/selfawaresoup/b296f3b82167484a96e4502e74ed3602
- https://github.com/cjstoddard/Clockworkpi-uConsole/
- https://hackergadgets.com/pages/hackergadgets-uconsole-rtl-sdr-lora-gps-rtc-usb-hub-all-in-one-extension-board-setup-guide
- https://austinsnerdythings.com/2025/02/14/revisiting-microsecond-accurate-ntp-for-raspberry-pi-with-gps-pps-in-2025/
- https://forum.clockworkpi.com/t/tar1090-for-uconsole-monitor-live-planes-in-your-area/17562

