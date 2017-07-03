#!/bin/sh

VER=`uname -r` #4.4.0-62-generic
VERSION=`uname -r | cut -d '-' -f -2`
apt download linux-signed-generic linux-signed-image-generic linux-headers-$VERSION linux-headers-$VER linux-image-$VER linux-headers-generic linux-headers-$VER linux-generic linux-image-extra-$VER linux-signed-image-$VER linux-image-generic

