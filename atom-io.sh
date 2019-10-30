#!/bin/sh

wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | gpg --dearmor > atom-io.gpg
sudo install -o root -g root -m 644 atom-io.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/atom-io.gpg] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom-io.list'
rm atom-io.gpg
