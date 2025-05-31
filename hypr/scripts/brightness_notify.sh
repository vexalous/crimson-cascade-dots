#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/colors.sh"

APP_NAME="Brightness"
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-high.svg"

get_brightness_percentage() {
    local current_brightness val_max_brightness
    current_brightness=$(brightnessctl g)
    val_max_brightness=$(brightnessctl m)
    if [[ -z "$val_max_brightness" || "$val_max_brightness" -eq 0 ]]; then
        echo 0
        return
    fi
    echo "$((current_brightness * 100 / val_max_brightness))"
}

get_brightness_icon() {
    local percentage="$1"
    if [ "$percentage" -lt 34 ]; then
        echo "$ICON_LOW"
    elif [ "$percentage" -lt 67 ]; then
        echo "$ICON_MEDIUM"
    else
        echo "$ICON_HIGH"
    fi
}

main() {
    local brightness_p icon
    brightness_p=$(get_brightness_percentage)
    icon=$(get_brightness_icon "$brightness_p")

    "$(dirname "$0")/notify.sh" \
        -t "Brightness" \
        -m "${brightness_p}%" \
        -i "$icon" \
        -a "$APP_NAME" \
        -p "$brightness_p"
}

main
