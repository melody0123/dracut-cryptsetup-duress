#!/bin/bash

trap 'echo "Error happened. Exit with error."' ERR
set -euo pipefail

usage () {
    echo "Usage: $0 -p <passwd> -d <block_device> [ -h | --help ]"
    echo "Generate a SHA512 hashed password for the block device. The device should be a LUKS container."
    echo "Once the password is entered during boot process, the corresponding encryption key will be erased from the LUKS header."
}

# output help info first
if [[ " $* " =~ " -h " || " $* " =~ " --help " ]]
then
    usage
    exit 0
fi

# check privilige level 
if [[ "$EUID" -ne 0 ]]
then
    echo "This script should be run as root." >&2
    exit 1
fi

# parse other options
while getopts "p:d:" opt
do
    case "$opt" in
        p)
            PASSWD="$OPTARG"
            ;;
        d)
            DEVICE="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# confirm the device is a LUKS container
cryptsetup isLuks "$DEVICE" || {
    echo "$DEVICE is not a LUKS container." >&2
    exit 1
}

# append hashed passwd and device to the /etc/dracut-cryptsetup-erase-signals file
HASH="$(openssl passwd -6 -salt "PfxSOM5uGKUQRmyL" "$PASSWD")"
echo "$DEVICE $HASH" | tee -a /etc/dracut-cryptsetup-erase-signals
chmod 600 /etc/dracut-cryptsetup-erase-signals
