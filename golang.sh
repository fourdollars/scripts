#!/bin/bash
# Quick golang installer for Debian/Ubuntu.
# Author: Shih-Yuan Lee (FourDollars)
# Licensed by GPLv3+

URL="https://golang.org/dl/"
ARCH=$(dpkg --print-architecture)
LATEST=$(wget "$URL" -O - 2>/dev/null | grep Archive -B 1 | grep "linux-$ARCH" | head -n1 | sed -ne 's/.*\(http[^"]*\).*/\1/p')
FILE=$(basename "$LATEST")
GOBIN="$HOME/.local/share/go/bin/go"

# Check if there is an older golang.
if [ -f "$GOBIN" ]; then
    if [ "$($GOBIN version | awk '{print $3}').linux-$ARCH.tar.gz" != "$FILE" ]; then
        rm -fr ~/.local/share/go
    else
        echo "$($GOBIN version) is already the latest version."
        exit
    fi
fi

SHA256=$(wget "$URL" -O - 2>/dev/null | grep "$LATEST" -A 5 | sed -ne 's/.*<tt>\([^<]*\)<\/tt>.*/\1/p')
echo "$SHA256" "$FILE"

while [ ! -f "/tmp/$FILE" ] || [ "$(sha256sum "/tmp/$FILE" | awk '{print $1}')" != "$SHA256" ]; do
    rm -f "/tmp/$FILE"
    wget -q "$LATEST" -O "/tmp/$FILE"
done

cd ~/.local/share || exit
rm -fr go
tar xf "/tmp/$FILE"
rm -f "/tmp/$FILE"
