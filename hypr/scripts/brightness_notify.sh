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

send_brightness_notification() {
    local percentage="$1"
    local icon_path="$2"
    notify-send -h string:x-canonical-private-synchronous:bright_notif \
                -h int:value:"$percentage" \
                -u low \
                -i "$icon_path" \
                -a "$APP_NAME" \
                "Brightness ${percentage}%" \
                --hint="string:fgcolor:$LIGHT_GRAY,string:bgcolor:$NEAR_BLACK,string:hlcolor:$CRIMSON"
}

main() {
    local brightness_p icon
    brightness_p=$(get_brightness_percentage)
    icon=$(get_brightness_icon "$brightness_p")
    send_brightness_notification "$brightness_p" "$icon"
}

main
