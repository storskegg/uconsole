#!/bin/bash

# Increase the charging rates of the two 18650's (I'm using LiteCore 3500mAh Li-ion cells.)
echo 'KERNEL=="axp20x-battery", ATTR{constant_charge_current_max}="2200000", ATTR{constant_charge_current}="2000000"' | sudo tee /etc/udev/rules.d/99-uconsole-charging.rules

# Installing packages
sudo apt update && sudo apt upgrade

sudo apt install mc links cmus htop tmux ffmpeg net-tools build-essential lame git tty-clock wget curl flex bison bc libavcodec-extra vim vlc -y

sudo apt install minicom sdrpp pps-tools gpsd gpsd-clients chrony foxtrotgps -y
sudo bash -c "echo 'pps-gpio' >> /etc/modules"

sudo apt install libgpiod-dev libyaml-cpp-dev libbluetooth-dev libusb-1.0-0-dev libi2c-dev openssl libssl-dev libulfius-dev liborcania-dev -y
