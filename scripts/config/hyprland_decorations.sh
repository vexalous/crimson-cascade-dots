#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/decorations.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Decorations"

cat << EOF > "$TARGET_FILE"
decoration {
    rounding = 8
    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        xray = true
        noise = 0.015
        contrast = 1.0
        brightness = 0.95
    }
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Decorations"
