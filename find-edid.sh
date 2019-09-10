#!/bin/bash

empty="d41d8cd98f00b204e9800998ecf8427e"

shopt -s globstar

for edid in /sys/devices/**/edid; do
    if [ "$(md5sum "$edid" | awk '{print $1}')" != "$empty" ]; then
        echo "$edid"
        break
    fi
done
