#!/usr/bin/env bash
set -euo pipefail

SHUTDOWN_STR="Shutdown"
REBOOT_STR="Reboot"
LOCK_STR="Lock Screen"
LOGOUT_STR="Logout"

display_menu() {
    local script_dir
    script_dir=$(dirname "$0")
    echo -e "$LOCK_STR\n$LOGOUT_STR\n$REBOOT_STR\n$SHUTDOWN_STR" | \
        rofi -dmenu -p "Power" -i -mesg "System Actions" -theme "$script_dir/../rofi/powermenu_theme.rasi"
}

execute_action() {
    local option="$1"
    case "$option" in
        "$SHUTDOWN_STR")
            systemctl poweroff
            ;;
        "$REBOOT_STR")
            systemctl reboot
            ;;
        "$LOCK_STR")
            hyprlock
            ;;
        "$LOGOUT_STR")
            loginctl terminate-session self
            ;;
    esac
}

main() {
    local selected_option
    selected_option=$(display_menu)
    if [ -n "$selected_option" ]; then
        execute_action "$selected_option"
    fi
}

main
