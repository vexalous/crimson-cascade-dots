#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/animations.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Animations"

cat << EOF > "$TARGET_FILE"
animations {
    enabled = true
    animation = windows, 1, 7, default, popin 60%
    animation = windowsIn, 1, 6, default, popin 30% 
    animation = windowsOut, 1, 7, default, popin 60%
    animation = border, 1, 10, default
    animation = borderangle, 1, 30, default, loop 
    animation = fade, 1, 5, default 
    animation = workspaces, 1, 7, default, slide 
    animation = specialWorkspace, 1, 6, default, slidevert
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Animations"
