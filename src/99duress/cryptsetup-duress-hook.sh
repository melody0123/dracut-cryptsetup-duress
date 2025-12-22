#!/bin/bash

set -eu

udevadm settle

# get uuid and disk model name to mimic real cryptsetup prompt
CRYPTTAB="$(cat /etc/crypttab)"
FIRST_LUKS_NAME="$(echo "$CRYPTTAB" | cut -d" " -f1)"
FIRST_UUID="$(echo "$CRYPTTAB" | cut -d" " -f2 | cut -d"=" -f2)"
FIRST_MODEL="$(udevadm info --query=property --property=ID_MODEL --value --name=/dev/disk/by-uuid/"$FIRST_UUID")"
USER_INPUT="$(systemd-ask-password --keyname="cryptsetup_key" "Please enter passphrase for disk $FIRST_MODEL ($FIRST_LUKS_NAME)")"

if [ "$(echo "$USER_INPUT" | /usr/bin/check-cryptsetup-duress-signal)" -eq 0 ]
then
    DEV="$(blkid -t TYPE="crypto_LUKS" -o device)"
    for dev in $DEV
    do
        cryptsetup erase -q "$dev"
        sleep 5  # mimic latency from calc
    done

    # mimic wrong password
    for _i in 1 2
    do
        systemd-ask-password "Please enter passphrase for disk $FIRST_MODEL ($FIRST_LUKS_NAME)"
        sleep 5
    done
fi
