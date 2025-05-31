#!/usr/bin/env bash
set -euo pipefail

if ! command -v pactl &> /dev/null; then
    echo "ERROR: 'pactl' command not found. This script requires 'pactl' to function." >&2

    if command -v notify-send &> /dev/null; then
        notify-send -u critical -a "Volume Script" "Error: 'pactl' command not found."
    fi
    exit 1
fi
source "$(dirname "$0")/colors.sh"

ICON_MUTED="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-muted.svg"
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-high.svg"
ICON_MIC_MUTED="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone-muted.svg"
ICON_MIC="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone.svg"

get_current_volume_percentage() {
    local volume_output
    volume_output=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '[0-9]+(?=%)' | head -n 1)
    if [[ -z "$volume_output" ]] || ! [[ "$volume_output" =~ ^[0-9]+$ ]]; then
        echo "Error: Could not parse volume percentage from pactl." >&2

        if command -v notify-send &> /dev/null; then
            notify-send -u normal -a "Volume Script" "Error: Could not parse volume from pactl."
        fi
        echo "0"
    else
        echo "$volume_output"
    fi
}

is_sink_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes
}

is_source_muted() {
    pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes
}

process_mic_mute_status() {
    local notification_title="Microphone"
    local icon_path
    local display_text
    local percentage_value

    if is_source_muted; then
        icon_path="$ICON_MIC_MUTED"
        display_text="Mic Muted"
        percentage_value=0
    else
        icon_path="$ICON_MIC"
        display_text="Mic On"
        percentage_value=100
    fi

    "$(dirname "$0")/notify.sh" \
        -t "$notification_title" \
        -m "$display_text" \
        -i "$icon_path" \
        -a "$notification_title" \
        -p "$percentage_value"
}

process_volume_status() {
    local notification_title="Volume"
    local current_volume
    current_volume=$(get_current_volume_percentage)
    local icon_path
    local display_text
    local percentage_value

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

    "$(dirname "$0")/notify.sh" \
        -t "$notification_title" \
        -m "$display_text" \
        -i "$icon_path" \
        -a "$notification_title" \
        -p "$percentage_value"
}

main() {
    if [[ "$1" == "MUTE" ]]; then
        process_mic_mute_status
    else
        process_volume_status
    fi
}

main
