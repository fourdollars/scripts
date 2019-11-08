#!/bin/sh

wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | gpg --dearmor > atom.gpg
sudo install -o root -g root -m 644 atom.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/atom.gpg] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
rm atom.gpg
