#!/usr/bin/env bash
set -euo pipefail
# Source color definitions (unused in this script but kept for consistency if it was intended for future use)
source "$(dirname "$0")/colors.sh"

# Application name for notifications
APP_NAME="Brightness"

# Icon paths for different brightness levels
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-high.svg"

# Calculates the current brightness percentage.
# Uses brightnessctl to get current and maximum brightness values.
get_brightness_percentage() {
    local current_brightness val_max_brightness
    current_brightness=$(brightnessctl g) # Get current brightness value
    val_max_brightness=$(brightnessctl m) # Get maximum brightness value

    # Handle cases where max brightness is not available or zero to prevent division by zero
    if [[ -z "$val_max_brightness" || "$val_max_brightness" -eq 0 ]]; then
        echo 0
        return
    fi
    # Calculate percentage: (current / max) * 100
    echo "$((current_brightness * 100 / val_max_brightness))"
}

# Selects an icon based on the brightness percentage.
# Args:
#   $1: Brightness percentage
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

# Main function to get brightness, select icon, and send notification.
main() {
    local brightness_p icon
    brightness_p=$(get_brightness_percentage)
    icon=$(get_brightness_icon "$brightness_p")

    # Call the notify.sh script to display the brightness notification
    # -t: Title
    # -m: Message (brightness percentage)
    # -i: Icon path
    # -a: Application name
    # -p: Progress value (used by some notification daemons for progress bars)
    "$(dirname "$0")/notify.sh"         -t "Brightness"         -m "${brightness_p}%"         -i "$icon"         -a "$APP_NAME"         -p "$brightness_p"
}

# Execute the main function
main
