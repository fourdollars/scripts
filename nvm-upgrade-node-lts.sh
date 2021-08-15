#!/bin/bash

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if grep dreamhost /etc/resolv.conf >/dev/null 2>&1; then
    CURRENT=$(readlink "$HOME/bin/node" | cut -d '/' -f 7)
else
    CURRENT=$(node --version)
fi

if [ -n "$1" ]; then
    LTS=$(nvm alias --no-colors | grep "$1" | tail -n 1 | awk '{print $1}' | cut -d '/' -f 2)
else
    LTS=$(nvm alias lts/* --no-colors | awk '{print $3}' | cut -d '/' -f 2)
fi

TARGET=$(nvm alias "$LTS" --no-colors | awk '{print $3}')

if [ "x$CURRENT" != "x$TARGET" ]; then
    echo "Upgrading $CURRENT to $TARGET (lts/$LTS) ..."
    nvm install "$TARGET"
    if grep dreamhost /etc/resolv.conf >/dev/null 2>&1; then
        setfattr -n user.pax.flags -v "mr" $(find "$NVM_DIR" -type f -iname "node" -o -iname "npm" -o -iname "npx")
    fi
    nvm alias default "$TARGET"
    nvm uninstall "$CURRENT"
    if grep dreamhost /etc/resolv.conf >/dev/null 2>&1; then
        ln -sf "$(nvm which "$TARGET")" "$HOME/bin/node"
    fi
fi

if [ "$(find "$(nvm cache dir)" | wc -l)" != 1 ]; then
    nvm cache clear
fi

nvm ls
