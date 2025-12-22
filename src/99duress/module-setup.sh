#!/bin/bash

check() {
    return 0
}

depends() {
    echo bash systemd systemd-ask-password
}

install() {
    inst_hook pre-mount 05 "$moddir/cryptsetup-duress-hook.sh"
    
    inst /etc/dracut-cryptsetup-duress-signals /etc/dracut-cryptsetup-duress-signals
    inst "$moddir/check-cryptsetup-duress-signal" /usr/bin/check-cryptsetup-duress-signal
    inst /etc/crypttab /etc/crypttab
    
    inst_multiple openssl cryptsetup cut sleep udevadm
}
