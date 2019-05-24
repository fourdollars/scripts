#! /usr/bin/env bash
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2015 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
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

url='https://kernel.ubuntu.com/~kernel-ppa/mainline'
script="$0"

set -e
eval set -- $(getopt -o "dhlruf:t:" -l "download-only,help,list,remove,update,from:,to:" -- $@)

while :; do
    case "$1" in
        ('-h'|'--help')
            cat <<ENDLINE
Usage:
    $0 [options] [versions] ...

Options:
    -h|--help          The manual of this script
    -d|--download-only Download only and not install
    -f|--from NUM      Lower bound of kernel version
    -t|--to   NUM      Upper bound of kernel version
    -l|--list          List available kernel versions
    -r|--remove        Remove mainline kernels
    -u|--update        Update the script itself
ENDLINE
            exit;;
        ('-d'|'--download-only')
            download_only="yes"
            shift;;
        ('-l'|'--list')
            list="yes"
            shift;;
        ('-r'|'--remove')
            remove="yes"
            shift;;
        ('-u'|'--update')
            update="yes"
            shift;;
        ('-f'|'--from')
            min="$2"
            shift 2;;
        ('-t'|'--to')
            max="$2"
            shift 2;;
        ('--')
            shift
            break;;
    esac
done

download_and_install_kernels ()
{
    if [ "$(uname -m)" = 'x86_64' ]; then
        arch='amd64'
    else
        arch='i386'
    fi
    for ver in $(eval echo $downloads); do
        ver="${ver/~rc/-rc}"
        debver="${ver/-rc/~rc}"
        pkgs=`wget -q $url/v$ver/ -O - | grep -o "linux[^\"]*\(all\|$arch\).deb" | grep -v -e lowlatency -e cloud | sort -u`
        for pkg in $pkgs; do
            [ -d "$PWD/kernels/v$debver" ] || mkdir -p "$PWD/kernels/v$debver"
            [ -f "$PWD/kernels/v$debver/$pkg" ] || wget -nv --show-progress "$url/v$ver/$pkg" -O "$PWD/kernels/v$debver/$pkg"
        done
        if [ -z "$pkgs" ]; then
            echo "There is no v${debver} mainline kernel to download."
        elif [ -z "$download_only" ]; then
            sudo dpkg -i $PWD/kernels/v$debver/*.deb
        fi
    done
}

check_available_kernels ()
{
    vers=`wget -q $url -O - | grep -o 'href="v[^"]*"' | grep -o '[0-9][^/]*' | sort -V`

    for ver in $vers; do
        ver="${ver/~rc/-rc}"
        debver="${ver/-rc/~rc}"
        if [ -n "$min" -a -n "$max" ]; then
            if dpkg --compare-versions $debver ge $min && dpkg --compare-versions $debver le $max; then
                downloads="$downloads $debver"
            fi
        elif [ -n "$min" ]; then
            if dpkg --compare-versions $debver ge $min; then
                downloads="$downloads $debver"
            fi
        elif [ -n "$max" ]; then
            if dpkg --compare-versions $debver le $max; then
                downloads="$downloads $debver"
            fi
        else
            downloads="$downloads $debver"
        fi
    done
}

select_kernels_to_install ()
{
    num=$(echo $downloads | xargs -n1 | wc -l)
    if [ -n "$min" -a -n "$max" ]; then
        items=$(echo $downloads | xargs -n1 | awk '{ print $1, "kernel", "on" }' | xargs echo)
    else
        items=$(echo $downloads | xargs -n1 | awk '{ print $1, "kernel", "off" }' | xargs echo)
    fi
    downloads=$(whiptail --clear --checklist "Select kernels to $action..." 0 0 $num $items 2>&1 >/dev/tty)
}

remove_installed_mainline_kernels ()
{
    installed=""
    for i in $(dpkg-query -W | grep linux-image-[2-9] | cut -d '-' -f 3-4); do
        if [ $(echo $i | cut -d '-' -f 2 | wc -c) -gt 6 ]; then
            installed="$installed $i"
        fi
    done
    for i in $(dpkg-query -W | grep linux-image-unsigned-[2-9] | cut -d '-' -f 4-5); do
        if [ $(echo $i | cut -d '-' -f 2 | wc -c) -gt 6 ]; then
            installed="$installed $i"
        fi
    done
    if [ -z "$installed" ]; then
        echo "There is no mainline kernel to remove."
        exit
    fi

    num=$(echo $installed | xargs -n1 | wc -l)
    installed=$(echo $installed | xargs -n1 | awk '{ print $1, "kernel", "off" }' | xargs echo)

    packages=""
    for i in $(whiptail --clear --checklist 'Select kernels to remove...' 0 0 $num $installed 2>&1 >/dev/tty); do
        packages="$packages $(dpkg-query -W | eval grep linux.*$i | awk '{print $1}')"
    done

    if [ -n "$packages" ]; then
        sudo apt-get purge $packages --yes
    fi
}

if [ -n "$update" ]; then
    wget https://raw.githubusercontent.com/fourdollars/scripts/master/mainline-kernels.sh -O $script
    exit
fi

if [ -n "$remove" ]; then
    remove_installed_mainline_kernels
    exit
fi

if [ -n "$*" ]; then
    noprompt=1
    downloads="$*"
fi

if [ -z "$download_only" ]; then
    action="install"
else
    action="download"
fi

if [ -z "$downloads" ]; then
    check_available_kernels
    if [ -z "$list" ]; then
        select_kernels_to_install
    else
        echo $downloads | xargs -n6 | column -t | sed 's/-rc/~rc/g'
        exit
    fi
fi

if [ -z "$noprompt" ] && [ -n "$downloads" ] && ! whiptail --title "Would you like to $action these kernels?" --yesno "$(echo $downloads | xargs -n1)" 0 0; then
    exit
fi

download_and_install_kernels

# vim:fileencodings=utf-8:expandtab:tabstop=4:shiftwidth=4:softtabstop=4
