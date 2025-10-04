#!/bin/bash

DEVICE=/dev/ttyS0

sudo printf "\xB5\x62\x0A\x04\x00\x00\x0E\x34" > $DEVICE   # poll MON‑VER
sudo dd if=$DEVICE bs=1 count=200 2>/dev/null | hexdump -C
