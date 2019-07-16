#!/bin/bash

line="$(wc -l "$0"| awk '{print $1}')"
grep something-unique-in-the-script -A "$((line-4))" "$0" | tail -n "$((line-5))" | stdbuf -oL bash -
exit
export LANG=C

(sudo apt update --yes -o APT::Status-Fd=2 && sudo apt full-upgrade --yes -o APT::Status-Fd=2) 3>&2 2>&1 1>&3 |
    awk -F: '{print $1, $3, $4}' |
    while read -r sta per msg; do
        case "$sta" in
            ('dlstatus')
                msg="Downloading indexes ...\n$msg"
                ;;
            ('pmstatus')
                msg="Updating packages ...\n$msg"
                ;;
        esac
        echo "# $msg"
        [[ $per =~ ^100 ]] || echo "$per"
    done |
    zenity \
        --title "Simple APT updater" \
        --progress \
        --width=240 \
        --auto-close \
        --no-cancel \
        --time-remaining
