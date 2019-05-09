#!/bin/bash

for pkg in openssh-server tmux; do
    if ! dpkg-query -s $pkg >/dev/null 2>&1; then
        sudo apt install --yes $pkg
    fi
done

if ! grep "tmux new-session -s ssh_tmux" ~/.bashrc >/dev/null 2>&1; then
    cat >> ~/.bashrc <<ENDFILE
if [ -z "\$TMUX" -a -n "\$SSH_CONNECTION" ]; then
    tmux new-session -s ssh_tmux || tmux attach-session -t ssh_tmux
    logout
fi
ENDFILE
fi
. ~/.bashrc

subdomain="$(echo $* | xargs echo -n | tr -d [:punct:] | tr -d  [:space:] | tr [:upper:] [:lower:])"

if [ -z "$subdomain" ]; then
    subdomain="$(shuf -n2 /usr/share/dict/american-english | tr -d [:punct:] | tr [:upper:] [:lower:] | xargs echo -n | tr -d  [:space:])"
fi

echo -e "Please execute \`\e[42mssh -J serveo.net $(whoami)@$subdomain\e[49m\` from remote to access this machine."

ssh -R $subdomain:22:localhost:22 serveo.net
