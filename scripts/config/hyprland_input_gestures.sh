#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/input_gestures.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Input Gestures"

cat << EOF > "$TARGET_FILE"
input {
    kb_layout = us
    kb_options = ctrl:nocaps
    follow_mouse = 1
    float_switch_override_focus = 0
    touchpad {
        disable_while_typing = true
    }
    accel_profile = flat
}

gestures {
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Input Gestures"
