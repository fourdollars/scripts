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

#export DEBFULLNAME=
#export DEBEMAIL=
#export DEBMAINTAINER=
#export KVER=3.5.0-23-generic
#AUTOINSTALL=no
#DEBTYPE=quilt # experimental
#DISTRO="$(lsb_release -c -s)"
#FIXPERMS=no
#FORCE=no
#MODALIASES=no
#MODALIASES_REGEX="(usb|pci):v"
#MODULES_CONF=('blacklist hello' 'blacklist kitty')
#POST_ADD=
#POST_BUILD=
#POST_INSTALL=
#POST_REMOVE=
#PRE_BUILD=
#PRE_INSTALL=
#REMAKE_INITRD=no

export LANG=C LANGUAGE=C QUILT_PATCHES="debian/patches"

set -e # -x # unmark this for debug messages.

[ -z "$1" ] && echo "Usage $0 { tarball | folder } [Debian source package folder]" && exit 0

# Detect name and version
if [ -d "$1" ]; then
    FOLDER="$(basename $1)"
    NAME="${FOLDER%-*}"
    VERSION="${FOLDER##*-}"
else
    TARBALL="$(basename $1)"
    FOLDER="${TARBALL%.tar*}"
    NAME="${FOLDER%-*}"
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
    cp -r "$NAME-$VERSION" "$BUILDROOT/$NAME-$VERSION/$NAME"
fi

cd "$BUILDROOT"
tar cJf "${NAME}_${VERSION}.orig.tar.xz" "$NAME-$VERSION"
cd -

# Check dkms-helper.env if any
if [ -e "${HOME}/.dkms-helper.env" ]; then
    . "${HOME}/.dkms-helper.env"
fi
if [ -n "$2" -a -d "$2" -a -f "$2"/dkms-helper.env ]; then
    DEB="$(readlink -e $2)"
    . "$DEB"/dkms-helper.env
fi

DKMS_SETUP="--no-prepare-kernel --no-clean-kernel --dkmstree $BUILDROOT/dkms --sourcetree $BUILDROOT/source --installtree $BUILDROOT/install"
DKMS_MOD="-m $NAME -v $VERSION"
DKMS_ARG="$DKMS_SETUP $DKMS_MOD"

OPTION=(POST_ADD POST_BUILD POST_INSTALL POST_REMOVE PRE_BUILD PRE_INSTALL)
EXPORT=(DISTRO FORCE MODALIASES MODALIASES_REGEX FIXPERMS REMAKE_INITRD AUTOINSTALL)

# Collect all pathes of optional scripts.
for ((i=0; i<${#OPTION[@]}; i++)); do
    HOOK="${OPTION[$i]}"
    eval FILE="\$${OPTION[$i]}"
    if [ -n "${FILE}" ]; then
        if [ -n "${DEB}" ]; then
            eval $HOOK="$(readlink -e ${DEB}/${NAME}/$(basename ${FILE}))"
        else
            eval $HOOK="$(readlink -e ${FILE})"
        fi
    fi
done

cd "$BUILDROOT/$NAME-$VERSION/$NAME"

# Adjust Makefile
if ! grep '^KVER?= $(shell uname -r)' Makefile; then
    cp -v Makefile Makefile.orig
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
    MODULE[$i]="$name"
    FOLDER[$i]="$path"
    i="$(expr 1 + $i)"
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

make clean || error 'The source does not support `make clean`. Please correct it.'

# AceLan's request doesn't work yet.
if false; then
if [ ! -e Kbuild ]; then
    mv -v Makefile.orig Kbuild
else
    rm Makefile.orig
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
AUTOINSTALL="yes"
MAKE="'make' -C ./ KVER=\$kernelver"
CLEAN="'make' -C ./ clean"
ENDLINE

if [ "${AUTOINSTALL:=yes}" = "yes" ]; then
    echo "AUTOINSTALL=\"${AUTOINSTALL}\"" >> dkms.conf
fi
if [ "${REMAKE_INITRD:=yes}" = "yes" ]; then
    echo "REMAKE_INITRD=\"${REMAKE_INITRD}\"" >> dkms.conf
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

# Insert modaliases into Debian source package
cd $BUILDROOT/dkms/$NAME/$VERSION/dsc
dpkg-source -x $NAME-dkms_$VERSION.dsc
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

# Adjust Makefile for better cooperation with version control system.
if [ -d $NAME-dkms-$VERSION/$NAME-$VERSION ]; then
    mv $NAME-dkms-$VERSION/$NAME-$VERSION $NAME-dkms-$VERSION/$NAME
    sed -i '/^#source tree/,+3 c #source tree\nifeq ("$(wildcard $(NAME))", "$(NAME)")\n\tcp -a "$(NAME)" "$(SRC)/$(NAME)-$(VERSION)"' $NAME-dkms-$VERSION/Makefile
fi

sed -i "1s/stable/${DISTRO:=$(lsb_release -c -s)}/" $NAME-dkms-$VERSION/debian/changelog
[ "${DEBTYPE:=native}" = "quilt" ] && sed -i "1s/$VERSION/$VERSION-1/" $NAME-dkms-$VERSION/debian/changelog

if [ -n "$DEBEMAIL" -a -n "$DEBFULLNAME" ]; then
    sed -i "s/Dynamic Kernel Modules Support Team <pkg-dkms-maint@lists.alioth.debian.org>/$DEBFULLNAME <$DEBEMAIL>/" $NAME-dkms-$VERSION/debian/changelog
fi

if [ -f "$DEB"/debian/changelog ]; then
    cat "$DEB"/debian/changelog >> $NAME-dkms-$VERSION/debian/changelog
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
rm -fr "$BUILDROOT"
