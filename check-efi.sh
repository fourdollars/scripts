#!/bin/sh

if [ ! -d ~/bin ]; then
    mkdir ~/bin
fi

if [ ! -f ~/bin/check_efi ]; then
    cat > ~/bin/check_efi <<ENDLINE
#!/bin/bash

if [ -f ~/.check_efi_counter ]; then
    . ~/.check_efi_counter
else
    COUNTER=1
fi

if [ ! -d /sys/firmware/efi ]; then
    zenity --info --title "No EFI System" --text "There is no /sys/firmware/efi"
else
    zenity --info --title "Would you like to stop?" --text "You have 5 seconds to decide. \$((COUNTER++)) time(s)" --ok-label Stop --timeout=5
    if [ \$? != 0 ]; then
        echo COUNTER=\$COUNTER > ~/.check_efi_counter
        dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 "org.freedesktop.login1.Manager.Reboot" boolean:true
    else
        rm ~/.config/autostart/check-efi.desktop
        rm ~/.check_efi_counter
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
