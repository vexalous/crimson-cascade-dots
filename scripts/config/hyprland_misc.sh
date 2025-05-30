#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="$HYPR_CONF_TARGET_DIR/misc.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

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

echo "$TARGET_FILE generated."
