#!/bin/bash

echo "This will perform automated setup of the uConsole. Your console will be rebooted"
echo "when complete. This may take some time."
echo ""
# shellcheck disable=SC2162
read -p "Press ENTER to continue, or CTRL-C to quit."

HOME_USER="/home/$(ls /home)"

# NOTE: these are relative. Will reference these relative to / or elsewhere
P_BOOT_FW="boot/firmware"
P_ETC_DEFAULT="etc/default"
P_ETC_CHRONY="etc/chrony"

DIR_UCS="$HOME_USER/.uc_setup"
DIR_UCS_GIT="$DIR_UCS/git"
DIR_UCS_BAK="$DIR_UCS/backups"
DIR_UCS_FIRMWARE="$DIR_UCS_BAK/$P_BOOT_FW"
DIR_UCS_ETC_DEFAULT="$DIR_UCS_BAK/$P_ETC_DEFAULT"
DIR_UCS_ETC_CHRONY="$DIR_UCS_BAK/$P_ETC_CHRONY"

FILE_UCS_FW_CFG_TXT="/$P_BOOT_FW/config.txt"
FILE_UCS_FW_CMD_TXT="/$P_BOOT_FW/cmdline.txt"
FILE_UCS_ETC_GPSD="/$P_ETC_DEFAULT/gpsd"
FILE_UCS_ETC_CHRONY="/$P_ETC_CHRONY/chrony.conf"

# Increase the charging rates of the two 18650's (I'm using LiteCore 3500mAh Li-ion cells.)
echo 'KERNEL=="axp20x-battery", ATTR{constant_charge_current_max}="2200000", ATTR{constant_charge_current}="2000000"' | sudo tee /etc/udev/rules.d/99-uconsole-charging.rules

# Scaffolding
mkdir -p "$DIR_UCS_GIT"
mkdir -p "$DIR_UCS_FIRMWARE"
mkdir -p "$DIR_UCS_ETC_DEFAULT"
mkdir -p "$DIR_UCS_ETC_CHRONY"

# Installing packages
sudo apt update && sudo apt upgrade

sudo apt install mc links cmus tmux net-tools build-essential lame git tty-clock flex bison bc libavcodec-extra vim -y
sudo apt install minicom sdrpp pps-tools gpsd gpsd-clients chrony foxtrotgps -y
sudo apt install libgpiod-dev libyaml-cpp-dev libbluetooth-dev libusb-1.0-0-dev libi2c-dev openssl libssl-dev libulfius-dev liborcania-dev -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Rust setup
export PATH="$HOME/.cargo/bin:$PATH"

# Small setup for PPS
sudo bash -c "echo 'pps-gpio' >> /etc/modules"

# Backups and adjustments (done after apt installs because some of the files don't exist yet)
git clone https://github.com/storskegg/uconsole.git "$DIR_UCS_GIT"

[[ -f $FILE_UCS_FW_CFG_TXT ]] && cp $FILE_UCS_FW_CFG_TXT "$DIR_UCS_FIRMWARE"
[[ -f $FILE_UCS_FW_CMD_TXT ]] && cp $FILE_UCS_FW_CMD_TXT "$DIR_UCS_FIRMWARE"
[[ -f $FILE_UCS_ETC_GPSD ]] && cp $FILE_UCS_ETC_GPSD "$DIR_UCS_ETC_DEFAULT"
[[ -f $FILE_UCS_ETC_CHRONY ]] & cp $FILE_UCS_ETC_CHRONY "$DIR_UCS_ETC_CHRONY"

cd "$DIR_UCS_GIT"/fs || exit
sudo cp ./$P_BOOT_FW/config.txt $FILE_UCS_FW_CFG_TXT
sudo cp ./$P_ETC_DEFAULT/gpsd $FILE_UCS_ETC_GPSD
sudo cp ./$P_ETC_CHRONY/chrony.conf $FILE_UCS_ETC_CHRONY
sudo cp ./home/w4pho/.inputrc "$HOME_USER"/.inputrc

# Remove the serial0 console parameter from /boot/firmware/cmdline.txt while retaining the rest of it
sudo perl -i -pe 's/console=(?:serial|ttyS)0,\d{4,6} ?//g' /$P_BOOT_FW/cmdline.txt

# ADS-B auto-installers
sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"
sudo bash -c "$(wget -nv -O - https://github.com/wiedehopf/tar1090/raw/master/install.sh)"

# Disable Devterm Printer service from Rex's image; required for meshtasticd
# sudo systemctl stop devterm-printer.service
# sudo systemctl disable devterm-printer.service

sudo reboot now
