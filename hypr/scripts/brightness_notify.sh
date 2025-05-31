#!/usr/bin/env bash
set -euo pipefail

# Source shared colors (though notify.sh also sources it, good for explicitness if this script used colors directly)
# shellcheck source=./colors.sh
source "$(dirname "$0")/colors.sh"

APP_NAME="Brightness" # Used for -a parameter to notify.sh
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
    echo $((current_brightness * 100 / val_max_brightness))
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
    local brightness_p icon notify_message
    brightness_p=$(get_brightness_percentage)
    icon=$(get_brightness_icon "$brightness_p")

    # The message for notify.sh -m parameter.
    # Since progress bar shows percentage, message can be more descriptive or empty.
    # For consistency with original, we'll pass "Brightness X%" as title, and X% as message for progress bar
    # notify.sh will use the -p value for int:value which typically replaces the body,
    # but it also passes the -m value as the summary.
    notify_message="${brightness_p}%"

    "$(dirname "$0")/notify.sh" \
        -a "$APP_NAME" \
        -t "Brightness" \
        -m "$notify_message" \
        -i "$icon" \
        -p "$brightness_p"
}

main
