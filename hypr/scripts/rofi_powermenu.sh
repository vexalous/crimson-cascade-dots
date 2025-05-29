#!/bin/bash
shutdown="Shutdown"
reboot="Reboot"
lock="Lock Screen"
logout="Logout"

selected_option=$(echo -e "$lock\n$logout\n$reboot\n$shutdown" | rofi -dmenu -p "Power" -i -mesg "System Actions")

case "$selected_option" in
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$lock")
        hyprlock
        ;;
    "$logout")
        loginctl terminate-session self
        ;;
esac
