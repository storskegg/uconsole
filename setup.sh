#!/bin/bash

echo "This will perform automated setup of the uConsole. Your console will be rebooted"
echo "when complete. This may take some time."
echo ""
read -p "Press ENTER to continue, or CTRL-C to quit."

export DIR_UCS="$HOME/.uc_setup"
export DIR_UCS_GIT="$DIR_UCS/git"
export DIR_UCS_BAK="$DIR_UCS/backups"
export DIR_UCS_FIRMWARE="$DIR_UCS_BAK/boot/firmware"
export DIR_UCS_ETC_DEFAULT="$DIR_UCS_BAK/etc/default"
export DIR_UCS_ETC_CHRONY="$DIR_UCS_BAK/etc/chrony"

export FILE_UCS_FW_CFG_TXT="/boot/firmware/config.txt"
export FILE_UCS_ETC_GPSD="/etc/default/gpsd"
export FILE_UCS_ETC_CHRONY="/etc/chrony/chrony.conf"

# Increase the charging rates of the two 18650's (I'm using LiteCore 3500mAh Li-ion cells.)
echo 'KERNEL=="axp20x-battery", ATTR{constant_charge_current_max}="2200000", ATTR{constant_charge_current}="2000000"' | sudo tee /etc/udev/rules.d/99-uconsole-charging.rules

# Installing packages
sudo apt update && sudo apt upgrade

sudo apt install mc links cmus htop tmux ffmpeg net-tools build-essential lame git tty-clock wget curl flex bison bc libavcodec-extra vim vlc -y
sudo apt install minicom sdrpp pps-tools gpsd gpsd-clients chrony foxtrotgps -y
sudo apt install libgpiod-dev libyaml-cpp-dev libbluetooth-dev libusb-1.0-0-dev libi2c-dev openssl libssl-dev libulfius-dev liborcania-dev -y

# Small setup for PPS
sudo bash -c "echo 'pps-gpio' >> /etc/modules"

# Backups, and file copies
mkdir -p $DIR_UCS_GIT
mkdir -p $DIR_UCS_FIRMWARE
mkdir -p $DIR_UCS_ETC_DEFAULT
mkdir -p $DIR_UCS_ETC_CHRONY

git clone https://github.com/storskegg/uconsole.git $DIR_UCS_GIT

[[ -f $FILE_UCS_FW_CFG_TXT ]] && cp $FILE_UCS_FW_CFG_TXT $DIR_UCS_FIRMWARE
[[ -f $FILE_UCS_ETC_GPSD ]] && cp $FILE_UCS_ETC_GPSD $DIR_UCS_ETC_DEFAULT
[[ -f $FILE_UCS_ETC_CHRONY ]] & cp $FILE_UCS_ETC_CHRONY $DIR_UCS_ETC_CHRONY

cd $DIR_UCS_GIT/fs
sudo cp ./boot/firmware/config.txt $FILE_UCS_FW_CFG_TXT
sudo cp ./etc/default/gpsd $FILE_UCS_ETC_GPSD
sudo cp ./etc/chrony/chrony.conf $FILE_UCS_ETC_CHRONY
sudo cp ./home/w4pho/.inputrc $HOME/.inputrc

# ADS-B auto-installers
sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"
sudo bash -c "$(wget -nv -O - https://github.com/wiedehopf/tar1090/raw/master/install.sh)"

# Disable Devterm Printer service from Rex's image; required for meshtasticd
# sudo systemctl stop devterm-printer.service
# sudo systemctl disable devterm-printer.service

sudo reboot now
