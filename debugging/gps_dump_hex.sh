#!/bin/bash

DEVICE=/dev/ttyS0

sudo cat $DEVICE | hexdump -C | head -n 20
