#!/bin/bash

## https://stackoverflow.com/a/53186875

totalmem=0

for mem in /sys/devices/system/memory/memory*; do
    if [[ "$(cat ${mem}/online)" == "1" ]]; then
        totalmem=$((totalmem+$((0x$(cat /sys/devices/system/memory/block_size_bytes)))))
    fi
done

echo ${totalmem} bytes
echo $((totalmem/1024**3)) GB
