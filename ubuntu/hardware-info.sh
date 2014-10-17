#!/bin/bash

export LANG=C
export LANGUAGE=C

platform="$1"

while [ -z "$platform" ]; do
    read -p "Please enter a platform codename: " platform
done

exec >$platform.log
exec 2>$platform.err

cat /proc/cpuinfo > $platform.cpuinfo
cat /proc/meminfo > $platform.meminfo
cat /sys/class/dmi/id/product_name > $platform.productname

if which lspci; then
    sudo lspci -vnn > $platform.lspci
    lspci -n | cut -d ' ' -f 3 | while read pciid; do
        sudo lspci -d $pciid -vvvnn > $platform.pci.${pciid/:/.}
    done
fi

if which dmidecode; then
    sudo dmidecode > $platform.dmidecode
fi

if which get-edid && which edid-decode; then
    sudo get-edid | edid-decode > $platform.edid-decode 2>&1
fi

if which cpuid; then
    sudo cpuid > $platform.cpuid
fi

if which lscpu; then
    sudo lscpu > $platform.lscpu
fi

if which lsusb; then
    sudo lsusb > $platform.lsusb
    lsusb | cut -d ' ' -f 6 | while read usbid; do
        sudo lsusb -d $usbid -v > $platform.usb.${usbid/:/.}
    done
fi

if which parted; then
    for disk in /dev/sd[a-z]; do
        sudo parted $disk print > $platform.parted.$(basename $disk)
    done
fi

if which hdparm; then
    for disk in /dev/sd[a-z]; do
        if sudo hdparm -i $disk; then
            sudo hdparm -I $disk > $platform.hdparm.$(basename $disk)
        fi
    done
fi

if which uname; then
    sudo uname -a > $platform.uname
fi

if [ -n "$DISPLAY" ] && which xinput; then
    xinput list --long > $platform.xinput
    touchpad="$(xinput | grep -i touchpad | sed 's/.*id=\([0-9]*\).*/\1/')"
    [ -n "$touchpad" ] && xinput list-props $touchpad > $platform.xinput.touchpad
    touchscreen="$(xinput | grep -i -e touchscreen -e 'touch screen' | sed 's/.*id=\([0-9]*\).*/\1/')"
    [ -n "$touchscreen" ] && xinput list-props $touchscreen > $platform.xinput.touchscreen
fi

if which acpidump; then
    acpidump -o $platform.acpidump
fi

sudo find /sys -name modalias -exec cat {} \; | sort > $platform.modaliases

# wget http://www.alsa-project.org/alsa-info.sh -O alsa-info.sh
if [ -e alsa-info.sh ]; then
    bash alsa-info.sh --no-upload --output $platform.alsa-info
fi
