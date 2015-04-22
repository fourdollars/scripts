#!/bin/sh

if [ ! -d ~/bin ]; then
    mkdir ~/bin
fi

if [ ! -f ~/bin/check_efi ]; then
    cat > ~/bin/check_efi <<ENDLINE
#!/bin/sh

if [ ! -d /sys/firmware/efi ]; then
    zenity --info --title "No EFI System" --text "There is no /sys/firmware/efi"
else
    zenity --question --title "Would you like to stop?" --text "You have 5 seconds to decide." --timeout=5
    RET=\$?
    if [ \$RET != 0 ]; then
        dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 "org.freedesktop.login1.Manager.Reboot" boolean:true
    elif [ \$RET = 0 ]; then
        rm ~/.config/autostart/check-efi.desktop
        rm ~/bin/check_efi
    fi
fi
ENDLINE
    chmod +x ~/bin/check_efi
fi

if [ ! -d ~/.config/autostart ]; then
    mkdir ~/.config/autostart    
fi

if [ ! -f ~/.config/autostart/check-efi.desktop ]; then
    cat > ~/.config/autostart/check-efi.desktop <<ENDLINE
[Desktop Entry]
Version=1.0
Type=Application
Name=Check EFI
Comment=Check EFI
Exec=$HOME/bin/check_efi
ENDLINE
fi
