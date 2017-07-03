#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Need root permission."
  exit
fi
# Check if Secure Boot is enabled
mokutil --sb-state | grep enabled > /dev/null 2>&1 || exit

# Check if there is any additional kernel module
ls /lib/modules/$(uname -r)/misc/vbox*.ko /lib/modules/$(uname -r)/updates/dkms/*.ko >/dev/null 2>&1 && exit

NAME="$(dmidecode -s system-product-name)"

if [ ! -f "$HOME/.config/dkms-self-signing/MOK.priv.aes" ]; then
  while :; do
    read -s -p "Please enter a password betweet 8 and 16 digits: " PASSWORD
    echo 
    read -s -p "Please enter the password again: " AGAIN
    echo 
    [ "$PASSWORD" = "$AGAIN" ] && break
  done
  unset AGAIN
  mkdir -p "$HOME/.config/dkms-self-signing/"
  chmod 700 "$HOME/.config/dkms-self-signing/"
  openssl req -new -nodes -utf8 -sha256 -days 36500 -batch -x509 -outform DER -out "$HOME/.config/dkms-self-signing/MOK.der" -keyout "$HOME/.config/dkms-self-signing/MOK.priv" -subj "/CN=DKMS self signing key for $NAME/"
  openssl aes-256-cbc -salt -in "$HOME/.config/dkms-self-signing/MOK.priv" -out "$HOME/.config/dkms-self-signing/MOK.priv.aes" -k "$PASSWORD"
  shred -u "$HOME/.config/dkms-self-signing/MOK.priv"
  chmod 600 "$HOME/.config/dkms-self-signing/MOK.der" "$HOME/.config/dkms-self-signing/MOK.priv.aes"
else
  read -s -p "Please enter the password of DKMS self signing key for $NAME: " PASSWORD
  echo 
  while ! openssl aes-256-cbc -d -salt -in "$HOME/.config/dkms-self-signing/MOK.priv.aes" -out /dev/null -k "$PASSWORD" > /dev/null 2>&1; do
    echo "The password is not correct."
    read -s -p "Please enter the password of DKMS self signing key for $NAME again: " PASSWORD
    echo 
  done
fi

if mokutil --list-enrolled | grep "DKMS self signing key for $NAME" > /dev/null 2>&1; then
  if ! mokutil --test-key "$HOME/.config/dkms-self-signing/MOK.der" | grep "is already enrolled" > /dev/null 2>&1; then
    mokutil --generate-hash="$PASSWORD" > /tmp/mokpass
    mokutil --reset --hash-file /tmp/mokpass
    shred -u /tmp/mokpass
    echo "Please reboot the system to reset MOK list."
  fi
else
  mokutil --generate-hash="$PASSWORD" > /tmp/mokpass
  mokutil --revoke-import
  mokutil --import "$HOME/.config/dkms-self-signing/MOK.der" --hash-file /tmp/mokpass
  shred -u /tmp/mokpass
  echo "Please reboot the system to import DKMS self signing key for $NAME."
fi

NOTSIGNED=0
for MODULE in $(ls /lib/modules/$(uname -r)/misc/vbox*.ko /lib/modules/$(uname -r)/updates/dkms/*.ko 2>/dev/null); do
  if hexdump -e '"%_p"' $MODULE | tail | grep signature > /dev/null 2>&1; then
    true
  else
    NOTSIGNED=1
  fi
done

if [ "$NOTSIGNED" -eq 0 ]; then
  echo "All DKMS modules are signed."
  exit
fi

openssl aes-256-cbc -d -salt -in "$HOME/.config/dkms-self-signing/MOK.priv.aes" -out "$HOME/.config/dkms-self-signing/MOK.priv" -k "$PASSWORD"
for MODULE in $(ls /lib/modules/$(uname -r)/misc/vbox*.ko /lib/modules/$(uname -r)/updates/dkms/*.ko 2>/dev/null); do
  if ! hexdump -e '"%_p"' $MODULE | tail | grep signature > /dev/null 2>&1; then
    /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 "$HOME/.config/dkms-self-signing/MOK.priv" "$HOME/.config/dkms-self-signing/MOK.der" $MODULE
    echo "$MODULE is signed."
  fi
done
shred -u "$HOME/.config/dkms-self-signing/MOK.priv"
