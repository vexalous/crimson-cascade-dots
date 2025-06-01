#!/usr/bin/env bash
# This script generates several helper scripts for Hyprland and places them
# in the target directory specified by the HYPR_SCRIPTS_TARGET_DIR environment variable.
# These helper scripts provide functionalities like idle management, brightness/volume notifications,
# and a power menu.
# It uses helper functions from 'common.sh'.
set -euo pipefail

# Source common library functions for configuration file management.
source "$(dirname "$0")/../config_lib/common.sh"

SCRIPT_DIR_NAME="Hyprland Helper Scripts"

# Prepare the target directory for the Hyprland helper scripts.
# This function (from common.sh) likely ensures the directory exists.
# HYPR_SCRIPTS_TARGET_DIR is an environment variable specifying where to write these scripts.
prepare_script_generation_dir "$HYPR_SCRIPTS_TARGET_DIR" "$SCRIPT_DIR_NAME"

# --- Generate idle_config.sh ---
# This script configures 'hypridle' for screen locking, DPMS, and system suspend.
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/idle_config.sh"
#!/usr/bin/env bash
set -euo pipefail
hypridle \
    timeout 300 'hyprlock' \
    timeout 330 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    timeout 600 'systemctl suspend' \
    before-sleep 'hyprlock && sleep 1' &
EOF
# Note: Detailed comments for idle_config.sh content are assumed to be in its source/template file.

# --- Generate brightness_notify.sh ---
# This script handles brightness adjustment notifications.
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/brightness_notify.sh"
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
EOF
# Note: Detailed comments for brightness_notify.sh content are assumed to be in its source/template file.

# --- Generate rofi_powermenu.sh ---
# This script displays a power menu using Rofi.
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/rofi_powermenu.sh"
#!/usr/bin/env bash
set -euo pipefail

SHUTDOWN_STR="Shutdown"
REBOOT_STR="Reboot"
LOCK_STR="Lock Screen"
LOGOUT_STR="Logout"

display_menu() {
    echo -e "$LOCK_STR\n$LOGOUT_STR\n$REBOOT_STR\n$SHUTDOWN_STR" | \
        rofi -dmenu -p "Power" -i -mesg "System Actions"
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
EOF
# Note: Detailed comments for rofi_powermenu.sh content are assumed to be in its source/template file.

# --- Generate volume_notify.sh ---
# This script provides notifications for volume changes and microphone mute status.
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/volume_notify.sh"
#!/usr/bin/env bash
set -euo pipefail

CRIMSON="#DC143C"
LIGHT_GRAY="#cccccc"
NEAR_BLACK="#0a0a0a"
ICON_MUTED="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-muted.svg"
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-high.svg"
ICON_MIC_MUTED="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone-muted.svg"
ICON_MIC="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone.svg"

get_current_volume_percentage() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -n 1
}

is_sink_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes
}

is_source_muted() {
    pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes
}

send_notification() {
    local notification_title="$1"
    local percentage_value="$2"
    local icon_path="$3"
    local display_text="$4"

    notify-send -h string:x-canonical-private-synchronous:vol_notif \
                -h int:value:"$percentage_value" \
                -u low \
                -i "$icon_path" \
                -a "$notification_title" \
                "$display_text" \
                --hint="string:fgcolor:$LIGHT_GRAY,string:bgcolor:$NEAR_BLACK,string:hlcolor:$CRIMSON"
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
    send_notification "$notification_title" "$percentage_value" "$icon_path" "$display_text"
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
    send_notification "$notification_title" "$percentage_value" "$icon_path" "$display_text"
}

main() {
    if [[ "$1" == "MUTE" ]]; then
        process_mic_mute_status
    else
        process_volume_status
    fi
}

main
EOF
# Note: Detailed comments for volume_notify.sh content are assumed to be in its source/template file.

# Finalize the script generation process for this directory.
finish_script_generation_dir "$HYPR_SCRIPTS_TARGET_DIR" "$SCRIPT_DIR_NAME"
