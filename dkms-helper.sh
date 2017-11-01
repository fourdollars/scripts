#!/bin/bash
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2013 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
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

## Customized Options

#DEBTYPE=quilt # experimental
#MODALIASES_REGEX="(usb|pci):v"
#KO_REGEX="intel"
#MODULES_CONF=('blacklist hello' 'blacklist kitty')
#BUILD_EXCLUSIVE_KERNEL="^4.4.*"

#AUTOINSTALL=no
#POST_ADD=
#POST_BUILD=
#POST_INSTALL=
#POST_REMOVE=
#PRE_BUILD=
#PRE_INSTALL=
#REMAKE_INITRD=no

CONF="${HOME}/.dkms-helper.env"
export LANG=C LANGUAGE=C QUILT_PATCHES="debian/patches"

set -e
eval set -- $(getopt -o "c:d:f:hk:m:n:sv:V" -l "config:,distribution:,firmware:,help,kernel:,message:,modalias:,name:,setup,vcs-bzr:,version:,verbose" -- "$@")

help_func()
{
    cat <<ENDLINE
Usage of $0 [options] tarball | folder
    -h|--help                  The manual of dkms-helper
    -c|--config       FILE     The config file of dkms-helper
    -d|--distribution DISTRO   The specified distribution or it will be determined by \`lsb_release -c -s\`
    -f|--firmware     DIR      The specified firmware folder
    -k|--kernel       KVER     The specified kernel version (Ex. 3.5.0-23-generic)
    -m|--message      MSG      The message in debian/changlog
    --modalias        MODALIAS The modalias string
    -n|--name         NAME     The specified name of DKMS package
    -s|--setup                 Set up dkms-helper eonviroment variables
    --vcs-bzr         Vcs-Bzr  The information in debian/control
    -v|--version      NUM      The specified version of DKMS package
    -V|--verbose               Show verbose messages
ENDLINE
}

config_func()
{
    if grep "^$1=" "${CONF}" >/dev/null 2>&1; then
        sed -i "s/^\($1=\).*/\1\"$2\"/" "${CONF}"
    else
        echo "$1=\"$2\"" >> "${CONF}"
    fi
}

setup_func()
{
    if [ -f "${CONF}" ]; then
        . "${CONF}"
    fi

    read -p "What is your full name? [$DEBFULLNAME] " result
    [ -z "$result" ] && result="$DEBFULLNAME"
    config_func "DEBFULLNAME" "$result"

    read -p "What is your email address? [$DEBEMAIL] " result
    [ -z "$result" ] && result="$DEBEMAIL"
    config_func "DEBEMAIL" "$result"

    read -p "What is your Debian package maintainer? [$DEBMAINTAINER] " result
    [ -z "$result" ] && result="$DEBMAINTAINER"
    config_func "DEBMAINTAINER" "$result"

    read -p "Would you like to force the kernel modules of DKMS package to be installed even when the existing kernel modules have higher version? [Y/n] " result
    if [ -z "$result" -o "$result" = "y" -o "$result" = "Y" ]; then
        result="yes"
    else
        result="no"
    fi
    config_func "FORCE" "$result"

    read -p "Would you like to keep the file permissions even after dkms changes them? [Y/n] " result
    if [ -z "$result" -o "$result" = "y" -o "$result" = "Y" ]; then
        result="yes"
    else
        result="no"
    fi
    config_func "FIXPERMS" "$result"

    read -p "Would you like to generate modaliases information from kernel modules? [Y/n] " result
    if [ -z "$result" -o "$result" = "y" -o "$result" = "Y" ]; then
        result="yes"
    else
        result="no"
    fi
    config_func "MODALIASES" "$result"

    echo -e "\nThe followings are your configuration for dkms-helper. You can also find them in ~/.dkms-helper.env.\n"
    cat "${CONF}"

    . "${CONF}"
    export DEBFULLNAME DEBEMAIL
}

if ! which dpkg-buildpackage > /dev/null 2>&1; then
    echo "Please install dpkg-dev by \`sudo apt install dpkg-dev\` first."
    exit
fi

while :; do
    case "$1" in
        ('-c'|'--config')
            . "$2"
            shift 2;;
        ('-d'|'--distribution')
            DISTRO="$2"
            shift 2;;
        ('-f'|'--firmware')
            FIRMWARE="$(readlink -f $2)"
            shift 2;;
        ('-h'|'--help')
            help_func
            exit;;
        ('-k'|'--kernel')
            KVER="$2"
            shift 2;;
        ('-m'|'--message')
            MESSAGE="$2"
            shift 2;;
        ('--modalias')
            MODALIAS="$MODALIAS $2"
            shift 2;;
        ('-n'|'--name')
            NAME="$2"
            shift 2;;
        ('-s'|'--setup')
            setup_func
            exit;;
        ('--vcs-bzr')
            VCS_BZR="$2"
            shift 2;;
        ('-v'|'--version')
            VERSION="$2"
            shift 2;;
        ('-V'|'--verbose')
            set -x
            shift;;
        ('--')
            shift
            break;;
    esac
done

if [ -z "$*" ]; then
    help_func
    exit
fi

if [ ! -f "${CONF}" ]; then
    setup_func
else
    . "${CONF}"
fi

if [ -n "$2" -a -d "$2" -a -f "$2"/dkms-helper.env ]; then
    DEBSRC="$(readlink -e $2)"
    . "$DEBSRC"/dkms-helper.env
fi

[ -z "$1" ] && help_func && exit

# Detect tarball or folder
if [ -d "$1" ]; then
    FOLDER="$(basename $1)"
else
    TARBALL="$(basename $1)"
    FOLDER="${TARBALL%.tar*}"
fi

if [ -z "$NAME" ]; then
    NAME="${FOLDER%-*}"
fi

if [ -z "$VERSION" ]; then
    VERSION="${FOLDER##*-}"
fi

# Find a temporary folder
while [ -z "$BUILDROOT" ]; do
    BUILDROOT="$(mktemp -d -u)"
    [ -e "$BUILDROOT" ] && BUILDROOT=''
done

error ()
{
    echo "$*"
    rm -fr "$BUILDROOT"
    exit 1
}

[ -n "$NAME" -a -n "$VERSION" ] || error "$1 is not a correct naming."

# Prepare original tarball
mkdir -p "$BUILDROOT/$NAME-$VERSION"

if [ -f "$1" ]; then
    tar xf "$1" -C "$BUILDROOT/$NAME-$VERSION" || error "Uncompress $1 failed."
    FOLDER="$(echo $BUILDROOT/$NAME-$VERSION/*)"
    [ -d "$FOLDER" ] || error "$FOLDER is not a folder."
    BASE="$(basename $FOLDER)"
    DIR="$(dirname $FOLDER)"
    mv -v "$FOLDER" "$DIR/$NAME"
else
    cp -r "$FOLDER" "$BUILDROOT/$NAME-$VERSION/$NAME"
fi

cd "$BUILDROOT"
tar cJf "${NAME}_${VERSION}.orig.tar.xz" "$NAME-$VERSION"
cd -

# Prepare DKMS environment variables
DKMS_SETUP="--no-prepare-kernel --no-clean-kernel --dkmstree $BUILDROOT/dkms --sourcetree $BUILDROOT/source --installtree $BUILDROOT/install"
DKMS_MOD="-m $NAME -v $VERSION"
DKMS_ARG="$DKMS_SETUP $DKMS_MOD"

OPTION=(POST_ADD POST_BUILD POST_INSTALL POST_REMOVE PRE_BUILD PRE_INSTALL)
EXPORT=(DISTRO FORCE MODALIASES MODALIASES_REGEX KO_REGEX FIXPERMS REMAKE_INITRD AUTOINSTALL BUILD_EXCLUSIVE_KERNEL)

# Collect all pathes of optional scripts.
for ((i=0; i<${#OPTION[@]}; i++)); do
    HOOK="${OPTION[$i]}"
    eval FILE="\$${OPTION[$i]}"
    if [ -n "${FILE}" ]; then
        if [ -n "${DEBSRC}" ]; then
            eval $HOOK="$(readlink -e ${DEBSRC}/${NAME}/$(basename ${FILE}))"
        else
            eval $HOOK="$(readlink -e ${FILE})"
        fi
    fi
done

cd "$BUILDROOT/$NAME-$VERSION/$NAME"

# Adjust Makefile
if ! grep '^KVER?= $(shell uname -r)' Makefile; then
    cp -v Makefile Makefile.dkms-helper
    sed -i 's/\($(shell uname -r)\|`uname -r`\)/$(KVER)/' Makefile
    sed -i '0,/\(^$\|^[^#]*$\)/ s/\(^$\|^[^#*]\)/KVER?= $(shell uname -r)\n&/' Makefile
fi

if [ -z "$KVER" ]; then
    HEADERS=($(dpkg-query -W | grep "linux-headers-.*-generic" | cut -f 1 | sed 's/linux-headers-//' | xargs echo))
    if [ "${#HEADERS[*]}" -ge 2 ]; then
        NUMBER=''
        while [ -z "$NUMBER" ]; do
            echo -e "\nChoose a linux version to build kernel module."
            for i in `seq 0 $(expr ${#HEADERS[*]} - 1)`; do
                echo -e "\t$i: ${HEADERS[$i]}"
            done
            read -p "Please enter the number: " NUMBER
            [ "$NUMBER" -ge 0 -a "$NUMBER" -lt "${#HEADERS[*]}" ] || NUMBER=''
        done
        export KVER="${HEADERS[$NUMBER]}"
    elif [ "${#HEADERS[*]}" -eq 1 ]; then
        export KVER="${HEADERS[0]}"
    else
        error "There is no linux kernel header files."
    fi
else
    export KVER
fi

make || error 'The source does not support `make` to build kernel module. Please correct it.'

# Collect kernel modules
i=
for module in `find -name '*.ko' | sort`; do
    if [ -z "$i" ]; then
        i=0
    fi
    name="$(basename $module)"
    name="${name/.ko/}"
    path="$(dirname $module | cut -c 3-)"
    if [ -z "$path" ]; then
        path="."
    fi
    if echo "$name" | egrep "$KO_REGEX"; then
        MODULE[$i]="$name"
        FOLDER[$i]="$path"
        i="$(expr 1 + $i)"
    fi
done

if [ -z "$i" ]; then
    echo 'There is no kernel module at all. Please check your source code.'
    exit 1
fi

# Generate modaliases
if [ "${MODALIASES:=yes}" = 'yes' ]; then
    if [ "${#MODULE[*]}" -eq 1 ]; then
        modinfo ${FOLDER[0]}/${MODULE[0]}.ko | grep ^alias | sed 's/alias:         /alias/' | while read line; do
            echo "$line hwe $NAME-dkms" | egrep "$MODALIASES_REGEX" || true
        done > .modaliases
    else
        NUMBER=''
        while [ -z "$NUMBER" ]; do
            echo -e "\nWhich one is your main kernel module?"
            for i in `seq 0 $(expr ${#MODULE[*]} - 1)`; do
                echo -e "\t$i: ${MODULE[$i]}"
            done
            read -p "Please enter the number: " NUMBER
            [ "$NUMBER" -ge 0 -a "$NUMBER" -lt "${#MODULE[*]}" ] || NUMBER=''
        done
        modinfo ${FOLDER[$NUMBER]}/${MODULE[$NUMBER]}.ko | grep ^alias | sed 's/alias:         /alias/' | while read line; do
            echo "$line hwe $NAME-dkms" | egrep "$MODALIASES_REGEX" || true
        done > .modaliases
    fi
else
    [ -f .modaliases ] && rm .modaliases
fi

if [ -n "$MODALIAS" ]; then
    MODALIASES='yes'
    for modalias in "$MODALIAS"; do
        echo "alias $modalias hwe $NAME-dkms" >> .modaliases
    done
    cat .modaliases
fi

make clean || error 'The source does not support `make clean`. Please correct it.'

# AceLan's request doesn't work yet.
if false; then
if [ ! -e Kbuild ]; then
    mv -v Makefile.dkms-helper Kbuild
else
    rm Makefile.dkms-helper
fi

cat > Makefile <<ENDLINE
ifeq (,\$(KERNELRELEASE))
KERNELBUILD := /lib/modules/\`uname -r\`/build
else
KERNELBUILD := /lib/modules/\$(KERNELRELEASE)/build
endif

all:
	make -C \$(KERNELBUILD) M=\$(shell pwd) modules

clean:
	make -C \$(KERNELBUILD) M=\$(shell pwd) clean
ENDLINE
fi

# Copy optional scripts into source tree
for ((i=0; i<${#OPTION[@]}; i++)); do
    eval FILE=\$${OPTION[$i]}
    if [ -n "${FILE}" ]; then
        cp -v "${FILE}" .
        chmod 755 "$(basename ${FILE})"
    fi
done

# Generate fixperms
if [ "${FIXPERMS:=yes}" = 'yes' ]; then
    find -type f -executable | cut -c 3- > .fixperms
else
    [ -f .fixperms ] && rm .fixperms
fi

# Generate dkms.conf
cat > dkms.conf <<ENDLINE
PACKAGE_NAME="$NAME"
PACKAGE_VERSION="$VERSION"
MAKE="'make' -C ./ KVER=\$kernelver"
CLEAN="'make' -C ./ clean"
ENDLINE

if [ "${AUTOINSTALL:=yes}" = "yes" ]; then
    echo "AUTOINSTALL=\"${AUTOINSTALL}\"" >> dkms.conf
fi

if [ "${REMAKE_INITRD:=yes}" = "yes" ]; then
    echo "REMAKE_INITRD=\"${REMAKE_INITRD}\"" >> dkms.conf
fi

if [ -n "$BUILD_EXCLUSIVE_KERNEL" ]; then
    echo "BUILD_EXCLUSIVE_KERNEL=\"${BUILD_EXCLUSIVE_KERNEL}\"" >> dkms.conf
else
    echo "BUILD_EXCLUSIVE_KERNEL=\"^$(echo $KVER | cut -d '.' -f -2).*\"" >> dkms.conf
fi

# Insert optional scripts into dkms.conf
for ((i=0; i<${#OPTION[@]}; i++)); do
    HOOK=${OPTION[$i]}
    eval FILE=\$${OPTION[$i]}
    if [ -n "${FILE}" ]; then
        echo "$HOOK=\"$(basename ${FILE}) $HOOK\"" >> dkms.conf
    fi
done

for i in `seq 0 $(expr ${#MODULE[*]} - 1)`; do
    cat >> dkms.conf <<ENDLINE
BUILT_MODULE_NAME[$i]="${MODULE[$i]}"
BUILT_MODULE_LOCATION[$i]="${FOLDER[$i]}/"
DEST_MODULE_LOCATION[$i]="/updates"

ENDLINE
done

if [ -n "${MODULES_CONF}" ]; then
    for i in `seq 0 $(expr ${#MODULES_CONF[*]} - 1)`; do
        echo "MODULES_CONF[$i]=\"${MODULES_CONF[$i]}\"" >> dkms.conf
    done
fi

cd -

# Generate Debian source package of DKMS
mkdir -p "$BUILDROOT/dkms" "$BUILDROOT/source" "$BUILDROOT/install"
cp -a "$BUILDROOT/$NAME-$VERSION/$NAME" "$BUILDROOT/source/$NAME-$VERSION"
dkms add $DKMS_ARG
dkms mkdsc $DKMS_ARG --source-only --legacy-postinst=0

cd $BUILDROOT/dkms/$NAME/$VERSION/dsc
dpkg-source -x $NAME-dkms_$VERSION.dsc
sed -i 's/in DKMS format.$/in DKMS format wrapped by dkms-helper./' $NAME-dkms-$VERSION/debian/control

# Insert modaliases into Debian source package
if [ "${MODALIASES:=yes}" = 'yes' ]; then
    if [ -n "$(cat $NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases)" ]; then
        mv $NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases $NAME-dkms-$VERSION/debian/modaliases
        if ! grep ^Build-Depends $NAME-dkms-$VERSION/debian/control | grep dh-modaliases; then
            sed -i 's/^Build-Depends.*/&, dh-modaliases/' $NAME-dkms-$VERSION/debian/control
        fi
        if ! grep ^'XB-Modaliases: ${modaliases}' $NAME-dkms-$VERSION/debian/control; then
            echo 'XB-Modaliases: ${modaliases}' >> $NAME-dkms-$VERSION/debian/control
        fi
        if ! grep dh_modaliases $NAME-dkms-$VERSION/debian/rules; then
            sed -i 's/binary-indep:.*/&\n\tdh_modaliases/' $NAME-dkms-$VERSION/debian/rules
        fi
    else
        [ -f "$NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases" ] && rm "$NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases"
    fi
else
    [ -f "$NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases" ] && rm "$NAME-dkms-$VERSION/$NAME-$VERSION/.modaliases"
fi

# Insert dkms modules to force install
if [ "${FORCE:=yes}" = 'yes' ]; then
    if ! grep modules_to_force_install $NAME-dkms-$VERSION/Makefile; then
        echo ${NAME} > $NAME-dkms-$VERSION/${NAME}.force
        cat >> $NAME-dkms-$VERSION/Makefile <<ENDLINE

#force, force install modules
ifeq ("\$(wildcard \$(NAME).force)", "\$(NAME).force")
	install -d \$(DESTDIR)/usr/share/dkms/modules_to_force_install
	install -m 644 \$(NAME).force \$(DESTDIR)/usr/share/dkms/modules_to_force_install
endif
ENDLINE
    fi
else
    [ -f "$NAME-dkms-$VERSION/${NAME}.force" ] && rm "$NAME-dkms-$VERSION/${NAME}.force"
fi

# Insert fixperms into Debian source package
if [ "${FIXPERMS:=yes}" = 'yes' ]; then
    if [ -n "$(cat $NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms)" ]; then
        mv $NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms $NAME-dkms-$VERSION/fixperms
        cat >> $NAME-dkms-$VERSION/Makefile <<ENDLINE

#fixperms, fix executable permission
ifeq ("\$(wildcard fixperms)", "fixperms")
	install -d "\$(SHARE)"
	install -m 644 fixperms "\$(SHARE)"
endif
ENDLINE
        sed -i "s,\t\tdkms_configure,\t\tcat /usr/share/\$PACKAGE_NAME/fixperms | while read file; do\n\t\t\tchmod +x /usr/src/\$NAME-\$CVERSION/\$file\n\t\tdone\n\t\tdkms_configure," $NAME-dkms-$VERSION/debian/postinst
    else
        [ -f "$NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms" ] && rm "$NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms"
    fi
else
    [ -f "$NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms" ] && rm "$NAME-dkms-$VERSION/$NAME-$VERSION/.fixperms"
fi

# Deal with firmware relative stuff
if [ -n "$FIRMWARE" -a -d "$FIRMWARE" ]; then
    cp -r "$FIRMWARE" $NAME-dkms-$VERSION/firmware
    sed -i "s/^Depends:\(.*\)/Depends:\1, $NAME-firmware (>= $VERSION)/" $NAME-dkms-$VERSION/debian/control
    sed -i 's/dh_installdeb/dh_install\n\tdh_installdeb/' $NAME-dkms-$VERSION/debian/rules
    cat >>$NAME-dkms-$VERSION/debian/control <<ENDLINE

Package: $NAME-firmware
Architecture: all
Description: $NAME's firmware wrapped by dkms-helper.
ENDLINE
    cat >>$NAME-dkms-$VERSION/debian/$NAME-firmware.install <<ENDLINE
firmware /usr/share/$NAME-$VERSION
ENDLINE
    cat >>$NAME-dkms-$VERSION/debian/$NAME-firmware.postinst <<ENDLINE
#!/bin/bash

set -e
case "\$1" in
	configure)
        find /usr/share/$NAME-$VERSION/firmware -type f | while read fw; do
            target=\${fw/\/usr\/share\/$NAME-$VERSION//lib}
            folder=\$(dirname \$target)
            dpkg-divert --package $NAME --divert \$target.$NAME --rename \$target
            [ ! -e "\$folder" ] && mkdir -p "\$folder"
            cp -av "\$fw" "\$target"
        done
	;;
esac

# dh_installdeb will replace this with shell code automatically
# generated by other debhelper scripts.

#DEBHELPER#

exit 0
ENDLINE
    cat >>$NAME-dkms-$VERSION/debian/$NAME-firmware.prerm <<ENDLINE
#!/bin/bash

set -e
case "\$1" in
	 remove|upgrade)
        find /usr/share/$NAME-$VERSION/firmware -type f | while read fw; do
            target=\${fw/\/usr\/share\/$NAME-$VERSION//lib}
            [ -f "\$target" ] && rm -v "\$target"
            dpkg-divert --package $NAME --rename --remove \$target
        done
	;;
esac

# dh_installdeb will replace this with shell code automatically
# generated by other debhelper scripts.

#DEBHELPER#

exit 0
ENDLINE
fi

# Adjust Makefile for better cooperation with version control system.
if [ -d $NAME-dkms-$VERSION/$NAME-$VERSION ]; then
    mv $NAME-dkms-$VERSION/$NAME-$VERSION $NAME-dkms-$VERSION/$NAME
    sed -i '/^#source tree/,+3 c #source tree\nifeq ("$(wildcard $(NAME))", "$(NAME)")\n\tcp -a "$(NAME)" "$(SRC)/$(NAME)-$(VERSION)"' $NAME-dkms-$VERSION/Makefile
fi

sed -i "1s/stable/${DISTRO:=$(lsb_release -c -s)}/" $NAME-dkms-$VERSION/debian/changelog
[ "${DEBTYPE:=native}" = "quilt" ] && sed -i "1s/$VERSION/$VERSION-1/" $NAME-dkms-$VERSION/debian/changelog

if [ -z "$MESSAGE" ]; then
    sed -i "3s/Automatically packaged by DKMS./Automatically packaged by DKMS helper./" $NAME-dkms-$VERSION/debian/changelog
else
    sed -i "3s/Automatically packaged by DKMS./$MESSAGE/" $NAME-dkms-$VERSION/debian/changelog
fi

if [ -n "$DEBEMAIL" -a -n "$DEBFULLNAME" ]; then
    sed -i "s/Dynamic Kernel Modules Support Team <pkg-dkms-maint@lists.alioth.debian.org>/$DEBFULLNAME <$DEBEMAIL>/" $NAME-dkms-$VERSION/debian/changelog
fi

if [ -f "$DEBSRC"/debian/changelog ]; then
    cat "$DEBSRC"/debian/changelog >> $NAME-dkms-$VERSION/debian/changelog
fi

if [ -n "$VCS_BZR" ]; then
    sed -i "s/^Maintainer:\(.*\)/Maintainer:\1\nVcs-Bzr: $VCS_BZR/" $NAME-dkms-$VERSION/debian/control
fi

if [ -n "$DEBMAINTAINER" ]; then
    sed -i "s/^Maintainer:.*/Maintainer: $DEBMAINTAINER/" $NAME-dkms-$VERSION/debian/control
fi

if [ ! -e "$NAME-dkms-$VERSION/debian/source" ]; then
    mkdir -p "$NAME-dkms-$VERSION/debian/source"
    echo "3.0 (${DEBTYPE:=native})" > "$NAME-dkms-$VERSION/debian/source/format"
fi

cat > $NAME-dkms-$VERSION/new-release.sh <<ENDLINE
#!/bin/bash

VER="\$1"

while [ -z "\$VER" ]; do
    read -p "Please enter a new version: " VER
done

shift

MSG="\$*"

while [ -z "\$MSG" ]; do
    read -p "Please enter a message of changelog: " MSG
done

sed -i "s/^VERSION=.*/VERSION=\$VER/" debian/rules debian/prerm
sed -i "s/^PACKAGE_VERSION=.*/PACKAGE_VERSION=\\"\$VER\\"/" $NAME/dkms.conf
dch -v "\$VER" "\$MSG"
ENDLINE

chmod +x $NAME-dkms-$VERSION/new-release.sh

# Export original settings
: > $NAME-dkms-$VERSION/dkms-helper.env
for ((i=0; i<${#EXPORT[@]}; i++)); do
    ITEM="${EXPORT[$i]}"
    eval VALUE="\$${EXPORT[$i]}"
    if [ -n "${VALUE}" ]; then
        echo "${ITEM}=${VALUE}" >> $NAME-dkms-$VERSION/dkms-helper.env
    fi
done
for ((i=0; i<${#OPTION[@]}; i++)); do
    ITEM="${OPTION[$i]}"
    eval VALUE="\$${OPTION[$i]}"
    if [ -n "${VALUE}" ]; then
        VALUE="$(basename $VALUE)"
        echo "${ITEM}=${VALUE}" >> $NAME-dkms-$VERSION/dkms-helper.env
    fi
done

if [ -n "${MODULES_CONF}" ]; then
    echo -n 'MODULES_CONF=(' >> $NAME-dkms-$VERSION/dkms-helper.env
    for i in `seq 0 $(expr ${#MODULES_CONF[*]} - 1)`; do
        echo -n "'${MODULES_CONF[$i]}' " >> $NAME-dkms-$VERSION/dkms-helper.env
    done
    echo ')' >> $NAME-dkms-$VERSION/dkms-helper.env
fi

cd -

cd "$BUILDROOT/dkms/$NAME/$VERSION/dsc/$NAME-dkms-$VERSION"
[ "${DEBTYPE:=native}" = "quilt" ] && mv "$BUILDROOT/${NAME}_${VERSION}.orig.tar.xz" "$BUILDROOT/dkms/$NAME/$VERSION/dsc/${NAME}-dkms_${VERSION}.orig.tar.xz"
dpkg-buildpackage -us -uc -tc
dpkg-buildpackage -us -uc -S
cd -
cp -v $BUILDROOT/dkms/$NAME/$VERSION/dsc/$NAME-dkms_$VERSION* .
if [ -n "$FIRMWARE" -a -f "$BUILDROOT/dkms/$NAME/$VERSION/dsc/$NAME-firmware_${VERSION}_all.deb" ]; then
    cp -v "$BUILDROOT/dkms/$NAME/$VERSION/dsc/$NAME-firmware_${VERSION}_all.deb" .
fi
rm -fr "$BUILDROOT"

# vim:fileencodings=utf-8:expandtab:tabstop=4:shiftwidth=4:softtabstop=4
