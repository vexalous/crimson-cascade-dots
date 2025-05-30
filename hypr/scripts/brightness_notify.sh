#!/usr/bin/env bash
set -euo pipefail

CRIMSON="#DC143C"
LIGHT_GRAY="#cccccc"
NEAR_BLACK="#0a0a0a"
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

main
