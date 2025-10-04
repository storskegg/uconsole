#!/bin/bash

DEVICE=/dev/ttyS0

# Show the current termios flags for /dev/ttyS0
sudo stty -F $DEVICE -a

# Force the UART to 9600 8N1 (no flow control)
sudo stty -F $DEVICE 9600 cs8 -cstopb -parenb -ixon -ixoff -crtscts
