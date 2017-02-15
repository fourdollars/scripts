#!/bin/sh

VER=`uname -r` #4.4.0-62-generic
apt download linux-signed-generic linux-signed-image-generic linux-headers-$VER linux-image-$VER linux-headers-generic linux-headers-$VER linux-generic linux-image-extra-$VER linux-signed-image-$VER linux-image-generic

