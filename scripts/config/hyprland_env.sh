#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/env.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Environment"

cat << EOF > "$TARGET_FILE"
env = XCURSOR_SIZE,$TARGET_CURSOR_SIZE
env = HYPRCURSOR_THEME,$TARGET_CURSOR_THEME
env = HYPRCURSOR_SIZE,$TARGET_CURSOR_SIZE
env = XCURSOR_THEME,$TARGET_CURSOR_THEME
env = QT_QPA_PLATFORM,wayland
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Environment"
