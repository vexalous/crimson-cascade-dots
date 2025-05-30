#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/misc.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Misc"

cat << EOF > "$TARGET_FILE"
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    enable_swallow = true
    swallow_regex = ^(Alacritty|kitty|foot|wezterm)$
    new_window_takes_over_fullscreen = 2
    focus_on_activate = true
    background_color = rgba(0a0a0aff)
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Misc"
