#!/bin/bash

mkdir -p ~/.local/share/keyrings/
pushd ~/.local/share/keyrings/ || exit
rm -fr ./*
STAMP=$(date +%s)
cat > default <<ENDLINE
headless
ENDLINE
cat > headless.keyring <<ENDLINE
[keyring]
display-name=Default keyring
ctime=$STAMP
mtime=0
lock-on-idle=false
lock-after=false

[1]
item-type=0
display-name=GNOME Remote Desktop RDP credentials
secret={'username': <'u'>, 'password': <'p'>}
mtime=$STAMP
ctime=$STAMP

[1:attribute0]
name=xdg:schema
type=string
value=org.gnome.RemoteDesktop.RdpCredentials
ENDLINE
popd || exit
gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp view-only false
mkdir -p "$HOME"/.local/share/gnome-remote-desktop/certificates/
rm -fr "$HOME"/.local/share/gnome-remote-desktop/certificates/*
openssl genrsa -out "$HOME"/.local/share/gnome-remote-desktop/certificates/rdp-tls.key 4096
openssl req -subj "/CN=https:\/\/bit.ly\/rdp-setup" -new -x509 -days 365 -key "$HOME"/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -out "$HOME"/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
gsettings set org.gnome.desktop.remote-desktop.rdp tls-key "$HOME"/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
gsettings set org.gnome.desktop.remote-desktop.rdp tls-cert "$HOME"/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
systemctl --user enable gnome-remote-desktop.service
systemctl --user restart gnome-remote-desktop.service
