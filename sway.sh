#!/bin/bash
# https://www.learnlinux.tv/how-i-set-up-the-sway-window-manager-on-debian-12/
# sudo apt install alacritty light sway swaybg swayidle swayimg swaylock waybar wofi fonts-font-awesome

mkdir -p ~/.config/sway ~/.config/waybar ~/.config/wofi

cat > ~/.config/sway/config <<EOF
# Ansible managed message here

#==================================================================================#
# Sway Window Manager Configuration File                                           #
#----------------------------------------------------------------------------------#
# Purpose: This configuration file enables you to tweak keyboard shortcuts, adjust #
# themes and colors, set the wallpaper, and more.                                  #
#                                                                                  #
# License: Creative Commons Attribution 4.0 International                          #
#                                                                                  #
# Pro-tip: While using Sway, you can trigger this configuration to be re-read by   #
# pressing Super + Shift + C.                                                      #
#==================================================================================#


#========================#
# Appearance and Theming #
#========================#
# Declare Colors:
set \$background #332b2b
set \$color_urgent #fb4934
set \$text_color #ffffff
set \$title_bg_unfocused #666666
set \$title_outline_active #0e844e
set \$title_outline_unfocused #332b2b

# Set Colors:           Border                   Background          Text          Indicator             Child Border
client.background       \$background
client.focused          \$title_outline_active    \$background         \$text_color   \$title_outline_active \$title_outline_active
client.focused_inactive \$title_outline_unfocused \$background         \$text_color   \$text_color           \$title_outline_unfocused
client.unfocused        \$title_outline_unfocused \$title_bg_unfocused \$text_color   \$title_outline_active
client.urgent           \$color_urgent            \$color_urgent       \$color_urgent \$color_urgent         \$color_urgent

# Add gaps in between all application windows:
gaps inner 8
gaps outer 3

# Configure the default border:
default_border pixel 2

# Set the Wallpaper:
output * bg \$HOME/.config/sway/wallpaper.jpg fill
# output DP-1 scale 2

#====================================#
# Activate the panel                 #
#====================================#
# Set the waybar command for the application launcher:
bar {
    swaybar_command waybar
}


#====================================#
# Keyboard Shortcuts (Sway-specific) #
#====================================#
# Set the modifier key to super:
set \$mod Mod4

# Set the ALT key to \$alt (since Mod1 is harder to remember):
set \$alt Mod1

# Set up a shortcut to reload this config file:
bindsym \$mod+Shift+c reload

# Quit your current session and return to the log-in manager/tty:
bindsym \$mod+Shift+e exec \$HOME/.config/sway/exit.sh

# Screen locking (automatic, with a timeout)
set \$lock swaylock -c 550000
exec swayidle -w \
    timeout 600 \$lock \
    timeout 570 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep \$lock

# Screen locking (manual)
set \$lock_screen exec bash ~/.config/sway/lock_screen.sh
bindsym \$mod+Escape exec \$lock_screen


#========================================#
# Keyboard Shortcuts (Window Management) #
#========================================#
# Move focus to another window:
bindsym \$mod+Left focus left
bindsym \$mod+Down focus down
bindsym \$mod+Up focus up
bindsym \$mod+Right focus right

# Move focus to another window ("cult of vim" version):
bindsym \$mod+j focus down
bindsym \$mod+h focus left
bindsym \$mod+l focus right
bindsym \$mod+k focus up

# Move the window:
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Down move down
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Right move right

# Move the the window ("cult of vim" version):
bindsym \$mod+Shift+h move left
bindsym \$mod+Shift+j move down
bindsym \$mod+Shift+k move up
bindsym \$mod+Shift+l move right

# Hold the modifier key and hold the left/right mouse button
# to drag or resize a window respectively. This isn't exclusive
# to floating windows:
floating_modifier \$mod normal

# Resizing containers:
mode "resize" {
    # Resize windows with arrow keys:
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    # "cult of vim" version:
    bindsym h resize shrink width 10px
    bindsym j resize grow height 10px
    bindsym k resize shrink height 10px
    bindsym l resize grow width 10px

    # Return to default mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym \$mod+r mode "resize"


#=================================#
# Keyboard Shortcuts (Workspaces) #
#=================================#
# Switch to workspace
set \$ws1 "1 - Communication"
set \$ws2 "2 - Browsing"
set \$ws3 "3 - System Administration"
set \$ws4 "4 - Learn Linux TV"
set \$ws5 "5 - Media"
set \$ws6 "6 - Writing"
set \$ws7 "7 - Homelab"
set \$ws8 "8 - Home Assistant"
set \$ws9 "9 - Unwind"

# Move between workspaces
bindsym \$mod+1 workspace \$ws1
bindsym \$mod+2 workspace \$ws2
bindsym \$mod+3 workspace \$ws3
bindsym \$mod+4 workspace \$ws4
bindsym \$mod+5 workspace \$ws5
bindsym \$mod+6 workspace \$ws6
bindsym \$mod+7 workspace \$ws7
bindsym \$mod+8 workspace \$ws8
bindsym \$mod+9 workspace \$ws9

# Move focused container to workspace
bindsym \$mod+Shift+1 move container to workspace \$ws1
bindsym \$mod+Shift+2 move container to workspace \$ws2
bindsym \$mod+Shift+3 move container to workspace \$ws3
bindsym \$mod+Shift+4 move container to workspace \$ws4
bindsym \$mod+Shift+5 move container to workspace \$ws5
bindsym \$mod+Shift+6 move container to workspace \$ws6
bindsym \$mod+Shift+7 move container to workspace \$ws7
bindsym \$mod+Shift+8 move container to workspace \$ws8
bindsym \$mod+Shift+9 move container to workspace \$ws9


#=============================#
# Keyboard Shortcuts (Layout) #
#=============================#
# You can "split" the current object of your focus with
# \$mod+b or \$mod+v, for horizontal and vertical splits
# respectively.
bindsym \$mod+b splith
bindsym \$mod+v splitv

# Switch the current container between different layout styles
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

# Make the current focus fullscreen
bindsym \$mod+f fullscreen

# Toggle the current focus between tiling and floating mode
bindsym \$mod+Shift+f floating toggle

# Swap focus between the tiling area and the floating area
bindsym \$mod+tab focus mode_toggle

# Move focus to the parent container
bindsym \$mod+a focus parent


#=================================#
# Keyboard Shortcuts (Scratchpad) #
#=================================#
# Sway has a "scratchpad", which is a bag of holding for windows.
# You can send windows there and get them back later.

# Move the currently focused window to the scratchpad
bindsym \$mod+Shift+minus move scratchpad

# Show the next scratchpad window or hide the focused scratchpad window.
# If there are multiple scratchpad windows, this command cycles through them.
bindsym \$mod+minus scratchpad show


#===============================#
# Keyboard Shortcuts (Hardware) #
#===============================#
# Audio
bindsym XF86AudioRaiseVolume exec "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+; pkill -RTMIN+8 waybar"
bindsym XF86AudioLowerVolume exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; pkill -RTMIN+8 waybar"
bindsym XF86AudioMute exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; pkill -RTMIN+8 waybar"

# Brightness
bindsym XF86MonBrightnessDown exec light -U 10
bindsym XF86MonBrightnessUp exec light -A 10


#=============================================#
# Keyboard Shortcuts (launching applications) #
#=============================================#
# Set up wofi to replace dmenu as the launcher of choice:
set \$menu wofi --show drun  -i | xargs swaymsg exec --

# Launch your browser:
bindsym \$mod+shift+b exec firefox

# Open a file manager:
bindsym ctrl+\$mod+f exec pcmanfm

# Open a terminal emulator:
set \$term alacritty
bindsym \$mod+t exec \$term

# Kill focused window:
bindsym \$mod+Shift+q kill

# Open the application launcher:
bindsym \$mod+space exec \$menu

# Open the application launcher (alternate version):
bindsym \$mod+d exec \$menu

#======#
# Misc #
#======#
include /etc/sway/config-vars.d/*
include /etc/sway/config.d/*
EOF

cat > ~/.config/sway/audio.sh <<EOF
#!/bin/bash

current_volume=\$(/usr/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@)

volume="\$(echo \$current_volume | cut -f 2 -d " " | sed 's/\.//g')"

if [[ \$current_volume == *"MUTED"* ]]; then
    echo "  ---"
fi

if [ "\$volume" -lt "100" ]; then
    volume="\${volume:1}"
fi

if [ "\$volume" -lt "10" ]; then
     volume="\${volume:1}"
fi


if [ "\$volume" -gt "99" ]; then
    echo "  \$volume%"
elif [ "\$volume" -gt "65" ]; then
    echo "  \$volume%"
elif [ "\$volume" -gt "30" ]; then
    echo "  \$volume%"
elif [ "\$volume" -gt "10" ]; then
    echo "  \$volume%"
elif [ "\$volume" -gt "0" ]; then
    echo "  \$volume%"
elif [ "\$volume" -lt "1" ]; then
    echo "  ---"
fi
EOF

chmod +x ~/.config/sway/audio.sh

cat > ~/.config/sway/exit.sh <<EOF
#!/bin/bash

if [[ ! \$(pgrep -x "swaynag") ]]; then
    swaynag --background 333333 --border 333333 --border-bottom 333333 --button-background 1F1F1F \
	    --button-border-size 0 --button-padding 8 --text FFFFFF --button-text FFFFFF --edge bottom \
	    -t warning -m 'Do you really want to log out?' -B 'You heard me!' 'swaymsg exit'
fi
EOF

chmod +x ~/.config/sway/exit.sh

cat > ~/.config/sway/lock_screen.sh <<EOF
#!/bin/sh

# Credit to the following for comming up with this:
# https://code.krister.ee/lock-screen-in-sway/
# To Do: The fancier screen lock mentioned on that page might be cool to try.

# Times the screen off and puts it to background
swayidle \
    timeout 10 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' &

# Locks the screen immediately
swaylock -c 550000

# Kills last background task so idle timer doesn't keep running
kill %%
EOF

chmod +x ~/.config/sway/lock_screen.sh

cat > ~/.config/waybar/config <<EOF
//====================================================================================================//
// Waybar Configuration File                                                                          //
//----------------------------------------------------------------------------------------------------//
// Purpose: Creates a minimalistic (yet functional) waybar at                                         //
// the top of the screen.                                                                             //
// themes and colors, set the wallpaper, and more.                                                    //
//                                                                                                    //
// License: Creative Commons Attribution 4.0 International                                            //
//                                                                                                    //
// Credit:                                                                                            //
// Battery section adapted from:                                                                      //
// https://github.com/Egosummiki/dotfiles/blob/master/waybar/config                                   //
//                                                                                                    //
// Pipewire audio adapted from:                                                                       //
// https://www.reddit.com/r/swaywm/comments/sks343/pwvolume_pipewire_volume_control_and_waybar_module //
//====================================================================================================//

{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 4,
    "margin-top": 0,
    "margin-bottom": 0,

    // Choose the order of the modules
    "modules-center": ["sway/workspaces", "tray"],
    "modules-left": ["custom/hostname"],
    "modules-right": [ "custom/audio","network","battery","clock"],

    // Configuration for individual modules
     "sway/workspaces": {
         "disable-scroll": true,
         "all-outputs": false,
         "format": "{name}",
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10,
    },

    "clock": {
        "timezone": "America/Detroit",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}",
    },

    "battery": {
        "states": {
            // "good": 95,
            "warning": 30,
            "critical": 15,
        },
        "format": "{icon} {capacity}%",
        "format-charging": "⚡{capacity}%",
        "format-plugged": " {capacity}%",
        "format-alt": "{time} {icon}",
        // "format-good": "", // An empty format will hide the module
        // "format-full": "",
        "format-icons": ["", "", "", "", ""],
    },

    "network": {
        // "interface": "wlp2*", // (Optional) To force the use of this interface
        "format-wifi": " {signalStrength}%",
        "format-ethernet": "Connected  ",
        "tooltip-format": "{ifname}: {gwaddr}",
        "format-linked": "{ifname} (No IP)",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click-right": "bash ~/.config/rofi/wifi_menu/rofi_wifi_menu",
    },

    "custom/audio": {
        "format": "{}",
        "signal": 8,
        "interval": "once",
        "exec": "/home/jay/.config/sway/audio.sh",
        "on-click": "pavucontrol",
    },

    "custom/hostname": {
        "format": "🖳  {}",
        "exec": "/usr/bin/hostname -f",
        "interval": "once",
        "on-click": "/usr/bin/rxvt -e /usr/bin/htop",
    },
}
EOF

cat > ~/.config/waybar/style.css <<EOF
* {
    font-family: Roboto, Helvetica, Arial, sans-serif;
    font-size: 14px;
    min-height: 0;
    padding-bottom: 2px;
    padding-top: 2px;
}

#battery {
    background: transparent;
    color: #ffffff;
    opacity: 0.7;
    padding: 2px 8px;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    padding: 2px 8px;
}

#battery.critical:not(.charging) {
    animation-direction: alternate;
    animation-duration: 0.5s;
    animation-iteration-count: infinite;
    animation-name: blink;
    animation-timing-function: linear;
    background-color: #f53c3c;
    color: gray;
}

#clock {
    background: #1f1f1f;
    color: #ffffff;
    margin-right: 4px;
    padding: 2px 8px;
}

#network {
    background: transparent;
    color: #ffffff;
    opacity: 0.7;
    padding: 2px 8px;
}

#network.disconnected {
    background: #1f1f1f;
    color: red;
}

#tray {
    background: #1f1f1f;
    color: #ffffff;
    margin-left: 18px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
    background: #1f1f1f;
    color: #ffffff;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background: #1f1f1f;
    color: #ffffff;
}

window#waybar {
    background: transparent;
    border-bottom: 1px solid #332b2b;
    transition-duration: .2s;
    transition-property: background-color;
}

#workspaces button:hover {
    /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
    background: @background;
    border-bottom: 1px solid #ffffff;
    box-shadow: inherit;
    color: #ffffff;
}

#workspaces button {
    background: transparent;
    color: #ffffff;
    margin-left: 2px;
    margin-right: 2px;
    opacity: 0.7;
}

#workspaces button.focused {
    background: #453e3d;
    color: #ffffff;
    opacity: 0.8;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}


/* Custom Stuff */
#custom-audio {
    background: transparent;
    color: #ffffff;
    opacity: 0.7;
    padding: 2px 8px;
}

#custom-hostname {
    background: transparent;
    color: #ffffff;
    padding: 2px 8px;
    opacity: 0.7;
}
EOF

cat > ~/.config/wofi/config <<EOF
allow_images=true
image_size=64
width=600
height=200
insensitive=true
mode=drun,run
columns=1
padding:5
lines=6
EOF

cat > ~/.config/wofi/style.css <<EOF
/* Notes below regarding the purpose of each setting is true to the best of my knowledge. */

#input {
	margin: 10px; /* how much padding there is around the input box */
	border: none; /* border around the input box */
	background-color: #453e3d; /* background color of the text input box itself */
        color: #ffffff; /* text color as you type inside the input box */
}

#inner-box {
	margin: 5px;
	border: none; /* horizontal bar that appears above the search results */
	background-color: #1f1f1f; /* background color behind the search results */
        color: #ffffff; /* text color of each search result */
}

#outer-box {
	margin: 5px; /* margin between the outer edges of the main window and its contents inside */
	border: none /* border around all the internal window components */
	background-color: #1f1f1f; /* background color of entire inner window */

}

#text {
	margin: 5px;
	border: none; /* border around each individual item within the search results */
	background-color: trans; /* background behind each individual item within the search results */
        color: ffffff;
}

/* Remove the search icon */
#input > image.left {
        -gtk-icon-transform:scaleX(0);
}

#scroll {
	margin: 5px;
	border: 2px solid #1f1f1f;
	background-color: #1f1f1f; /* background color behind the search slider */
}

window {
	margin: 15px;
	border: 3px solid green; /* border around the entire window */
	background-color: #1f1f1f;
}
EOF

wget https://www.learnlinux.tv/wp-content/uploads/2023/11/wallpaper.jpg -O ~/.config/sway/wallpaper.jpg
