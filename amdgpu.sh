#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This needs the root permission."
    exit
fi

set -x

lspci | grep -e VGA | awk '{print $1}' | while read slot; do lspci -x -s $slot; done

[ -e /sys/kernel/debug/vgaswitcheroo/switch ] && cat /sys/kernel/debug/vgaswitcheroo/switch
[ -e /sys/kernel/debug/dri/0/amdgpu_pm_info ] && cat /sys/kernel/debug/dri/0/amdgpu_pm_info
