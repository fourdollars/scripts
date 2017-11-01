#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 [device node, such as /dev/sdb] [Label Name]"
    exit
fi

if [ ! -z "$2" ]; then
    LABEL="$2"
else
    LABEL="FreeDOS"
fi

sudo apt install makebootfat --yes

folder=`mktemp -u -d`

mkdir -p $folder/fs-root
cd $folder
wget http://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.0/pkgs/kernels.zip
unzip kernels.zip source/ukernel/boot/fat*.bin
cp -v source/ukernel/boot/fat*.bin .

wget http://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.0/pkgs/commandx.zip
wget http://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.0/pkgs/unstablx.zip
unzip commandx.zip bin/command.com
unzip unstablx.zip bin/kernel.sys
cp -v bin/kernel.sys bin/command.com fs-root/

sudo makebootfat -o $1 -L "$LABEL" -E 255 -1 fat12.bin -2 fat16.bin -3 fat32lba.bin -m /usr/lib/syslinux/mbr/mbr.bin fs-root/
cd
rm -fr $folder
