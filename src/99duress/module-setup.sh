#!/bin/bash

check() {
    # include this module if duress signal is registered
    if [ -f /etc/dracut-cryptsetup-duress-signals ]
    then
        return 0
    else
        return 1
    fi

    # include this module if duress mode is chosen
    if [ -f /etc/dracut-cryptsetup-duress-mode ]
    then
        return 0
    else
        return 1
    fi
}

depends() {
    echo bash systemd systemd-ask-password systemd-cryptsetup crypt # tpm2-tss
}

install() {
    # registered duress signal and mode
    inst /etc/dracut-cryptsetup-duress-signals /etc/dracut-cryptsetup-duress-signals
    inst /etc/dracut-cryptsetup-duress-mode /etc/dracut-cryptsetup-duress-mode

    # luks mapper name for rootfs and disk model
    local _crypttab_path
    _crypttab_path="$initdir/etc/crypttab"

    if [ -f "$_crypttab_path" ]
    then
        local _mapper_name
        _mapper_name="$(head -1 "$_crypttab_path" | awk '{ print $1 }' )"
    fi

    # backing device model name
    local _dev_model
    local _dev_file
    _dev_file="$(cryptsetup status /dev/mapper/"$_mapper_name" | grep "device" | awk '{ print $2 }')"
    _dev_model="$(udevadm info --query=property --property=ID_MODEL --value --name="$_dev_file")"

    # save to initramfs
    echo "$_mapper_name $_dev_model" > "$initdir"/etc/dracut-cryptsetup-duress-rootfs-info

    # initramfs-time script run by systemd service. logic of duress signal
    inst "$moddir/cryptsetup-duress-hook.sh" /usr/bin/cryptsetup-duress-hook.sh
    
    # binary utilities used by duress script
    inst_multiple openssl cut sleep cryptsetup head keyctl # tpm2 tpm2_clear

    # install systemd service
    inst_simple "$moddir/cryptsetup-duress.service" \
        /usr/lib/systemd/system/cryptsetup-duress.service
    mkdir -p "$initdir/usr/lib/systemd/system/sysinit.target.wants"
    ln_r "/usr/lib/systemd/system/cryptsetup-duress.service" \
         "/usr/lib/systemd/system/sysinit.target.wants/cryptsetup-duress.service"
}
