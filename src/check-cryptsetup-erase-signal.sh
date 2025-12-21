#!/bin/bash

set -xeuo pipefail
trap 'echo "An error occurred"' ERR

usage() {
    echo "$0 <password>" >&2
    echo "This script will check if signal is presented in /etc/dracut-cryptsetup-erase-signals or not." >&2
    echo "If yes, return 0. Otherwise return 1." >&2
    echo "We assume this script will be running in the early boot phase where root is the user." >&2
}

if [[ " $* " =~ " -h " || " $* " =~ " --help " ]]
then
    usage
    exit 0
fi

PASSWD="$1"

while read -r line
do
    salt="$(echo "$line" | cut -d'$' -f3)"
    hashed_in_tab="$(echo "$line" | cut -d'$' -f4)"
    hashed_user="$(echo "$PASSWD" | openssl passwd -6 -salt "$salt" -stdin | cut -d'$' -f4)"
    if [[ "$hashed_in_tab" == "$hashed_user" ]]
    then
        exit 0
    fi
done < /etc/dracut-cryptsetup-erase-signals

exit 1
