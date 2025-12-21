#!/bin/bash

check() {
    # Always include this module
    return 0
}

depends() {
    # We need bash, cryptsetup tools, and key management
    echo bash systemd systemd-ask-password
}

install() {
    # Install the script that runs at boot
    inst_hook pre-mount 05 "$moddir/luks-erase-hook.sh"
    
    # Install our hash file (Safety risk? Yes, but it's a hash)
    inst /etc/dracut-cryptsetup-erase-signals /etc/dracut-cryptsetup-erase-signals
    inst "$moddir/check-cryptsetup-erase-signal" /usr/bin/check-cryptsetup-erase-signal
    
    # Install necessary binaries (keyctl is crucial)
    inst_multiple keyctl openssl
}
