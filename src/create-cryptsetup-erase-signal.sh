#!/bin/bash

trap 'echo "Error happened. Exit with error."' ERR
set -euo pipefail

usage () {
    echo "Usage: $0 -p <passwd> [ -h | --help ]"
    echo "Generate a SHA512 hashed password used as erasure signal"
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
while getopts "p:" opt
do
    case "$opt" in
        p)
            PASSWD="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# append hashed passwd and device to the /etc/dracut-cryptsetup-erase-signals file
HASH="$(openssl passwd -6 "$PASSWD")"
echo "$HASH" | tee -a /etc/dracut-cryptsetup-erase-signals
chmod 600 /etc/dracut-cryptsetup-erase-signals
