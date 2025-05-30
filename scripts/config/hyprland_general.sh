#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/general.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland General"

cat << EOF > "$TARGET_FILE"
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(DC143Cee) rgba(8B0000aa) 45deg
    col.inactive_border = rgba(3d3d3dcc)
    layout = dwindle
    allow_tearing = false
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland General"
