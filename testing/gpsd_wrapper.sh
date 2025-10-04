#!/bin/bash
# /usr/local/bin/gpsd_fixed.sh
DEV="/dev/ttyS0"

# -------------------------------------------------
# 1️⃣ Force the UART to the known‑good mode
#    9600 baud, 8N1, no flow‑control
# -------------------------------------------------
stty -F "$DEV" 9600 cs8 -cstopb -parenb -ixon -ixoff -crtscts

# -------------------------------------------------
# 2️⃣ Start gpsd *without* letting it re‑configure the port
#    -N  : stay in foreground (easier to debug)
#    -G  : listen on all interfaces (optional)
#    -n  : start even if no device is present yet
#    -F  : explicit socket path (default)
# -------------------------------------------------
exec /usr/sbin/gpsd -N -G -n -F /var/run/gpsd.sock "$DEV"
