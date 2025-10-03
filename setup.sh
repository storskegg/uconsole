#!/bin/bash

# Increase the charging rates of the two 18650's (I'm using LiteCore 3500mAh Li-ion cells.)
echo 'KERNEL=="axp20x-battery", ATTR{constant_charge_current_max}="2200000", ATTR{constant_charge_current}="2000000"' | sudo tee /etc/udev/rules.d/99-uconsole-charging.rules

# Installing packages
sudo apt update && sudo apt upgrade

sudo apt install mc links cmus htop tmux ffmpeg net-tools build-essential lame git tty-clock wget curl flex bison bc libavcodec-extra vim vlc -y
sudo apt install minicom sdrpp pps-tools gpsd gpsd-clients chrony foxtrotgps -y
sudo apt install libgpiod-dev libyaml-cpp-dev libbluetooth-dev libusb-1.0-0-dev libi2c-dev openssl libssl-dev libulfius-dev liborcania-dev -y

# Small setup for PPS
sudo bash -c "echo 'pps-gpio' >> /etc/modules"

# ADS-B auto-installers
sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"
sudo bash -c "$(wget -nv -O - https://github.com/wiedehopf/tar1090/raw/master/install.sh)"

# Disable Devterm Printer service from Rex's image
sudo systemctl stop devterm-printer.service
sudo systemctl disable devterm-printer.service

