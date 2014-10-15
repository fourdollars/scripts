#! /usr/bin/env bash
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2014 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

usage()
{
    cat << ENDLINE
Usage:
    $0 initrd.new.gz initrd.old.lz [initrd.lz]
ENDLINE
}

new="$(readlink -f $1)"
old="$(readlink -f $2)"

if [ -z "$old" -o -z "$new" ]; then
    usage
    exit
fi

set -e

tmp="$(mktemp -u)"
while [ -e "$tmp" ]; do
    tmp="$(mktemp -u)"
done

if [ -z "$3" ]; then
    TARGET="$PWD/initrd.lz"
else
    TARGET="$PWD/$3"
fi

mkdir -p "$tmp"
echo "$tmp"

cd "$tmp"
mkdir new old

cd new
gzip -dc "$new" | cpio -id
cd ..

cd old
lzma -dc -S .lz "$old" | cpio -id
cd ..

cp old/conf/uuid.conf new/conf/uuid.conf
cat new/conf/uuid.conf

cd new
find . | cpio --quiet --dereference -o -H newc | lzma -7 > "$TARGET"

rm -fr "$tmp"

# vim:fileencodings=utf-8:expandtab:tabstop=4:shiftwidth=4:softtabstop=4
