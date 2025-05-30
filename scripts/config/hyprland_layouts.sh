#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/layouts.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Layouts"

cat << EOF > "$TARGET_FILE"
dwindle {
    preserve_split = true
}

master {
}
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Layouts"
