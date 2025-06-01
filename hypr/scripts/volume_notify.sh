#!/usr/bin/env bash
# This script provides notifications for volume changes and microphone mute status.
# It uses 'pactl' to get audio information and 'notify.sh' (custom script) to display notifications.
set -euo pipefail

# Check if 'pactl' is available, as it's essential for this script.
if ! command -v pactl &> /dev/null; then
    echo "ERROR: 'pactl' command not found. This script requires 'pactl' to function." >&2

    # If notify-send is available, also send a desktop notification about the error.
    if command -v notify-send &> /dev/null; then
        notify-send -u critical -a "Volume Script" "Error: 'pactl' command not found."
    fi
    exit 1
fi

# Source color definitions (likely for notify.sh)
# shellcheck source=./colors.sh
source "$(dirname "$0")/colors.sh"

# Icon paths for various volume and microphone states
ICON_MUTED="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-muted.svg"
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-high.svg"
ICON_MIC_MUTED="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone-muted.svg"
ICON_MIC="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone.svg"

# Retrieves the current volume percentage for the default sink (output device).
# Parses pactl output to find the volume.
get_current_volume_percentage() {
    local volume_output
    # Get volume for @DEFAULT_SINK@, filter for lines with percentages, extract the number.
    volume_output=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '[0-9]+(?=%)' | head -n 1)

    # Validate if volume was successfully parsed
    if [[ -z "$volume_output" ]] || ! [[ "$volume_output" =~ ^[0-9]+$ ]]; then
        echo "Error: Could not parse volume percentage from pactl." >&2
        # Send a desktop notification about the parsing error if possible
        if command -v notify-send &> /dev/null; then
            notify-send -u normal -a "Volume Script" "Error: Could not parse volume from pactl."
        fi
        echo "0" # Return 0 as a fallback
    else
        echo "$volume_output"
    fi
}

# Checks if the default sink (output device) is muted.
# Returns 0 (true) if muted, 1 (false) otherwise.
is_sink_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes
}

# Checks if the default source (input device/microphone) is muted.
# Returns 0 (true) if muted, 1 (false) otherwise.
is_source_muted() {
    pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes
}

# Processes and displays a notification for the microphone mute status.
process_mic_mute_status() {
    local notification_title="Microphone"
    local icon_path
    local display_text
    local percentage_value # For progress bar in notification

    if is_source_muted; then
        icon_path="$ICON_MIC_MUTED"
        display_text="Mic Muted"
        percentage_value=0 # Show progress bar as empty/off
    else
        icon_path="$ICON_MIC"
        display_text="Mic On"
        percentage_value=100 # Show progress bar as full/on
    fi

    # Call the notify.sh script to display the microphone status
    "$(dirname "$0")/notify.sh" \
        -t "$notification_title" \
        -m "$display_text" \
        -i "$icon_path" \
        -a "$notification_title" \
        -p "$percentage_value"
}

# Processes and displays a notification for the current volume status.
process_volume_status() {
    local notification_title="Volume"
    local current_volume
    current_volume=$(get_current_volume_percentage)
    local icon_path
    local display_text
    local percentage_value # For progress bar in notification

    if is_sink_muted || [ "$current_volume" -eq 0 ]; then
        icon_path="$ICON_MUTED"
        display_text="Muted"
        percentage_value=0
    elif [ "$current_volume" -lt 34 ]; then
        icon_path="$ICON_LOW"
        display_text="${current_volume}%"
        percentage_value="$current_volume"
    elif [ "$current_volume" -lt 67 ]; then
        icon_path="$ICON_MEDIUM"
        display_text="${current_volume}%"
        percentage_value="$current_volume"
    else
        icon_path="$ICON_HIGH"
        display_text="${current_volume}%"
        percentage_value="$current_volume"
    fi

    # Call the notify.sh script to display the volume status
    "$(dirname "$0")/notify.sh" \
        -t "$notification_title" \
        -m "$display_text" \
        -i "$icon_path" \
        -a "$notification_title" \
        -p "$percentage_value"
}

# Main function: Determines whether to show mic status or volume status.
# Expects one argument: "MUTE" for microphone status, anything else for volume.
main() {
    if [[ "${1:-}" == "MUTE" ]]; then # Use ${1:-} to provide a default empty value if $1 is not set
        process_mic_mute_status
    else
        process_volume_status
    fi
}

# Execute the main function with the first command-line argument
main "${1:-}"
