#!/bin/sh

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > sublimehq-pub.gpg
sudo install -o root -g root -m 644 sublimehq-pub.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/sublimehq-pub.gpg] https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list'
rm sublimehq-pub.gpg
