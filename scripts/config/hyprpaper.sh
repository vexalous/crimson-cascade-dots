#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

HYPRPAPER_CONF_FILE="$CONFIG_TARGET_DIR/hypr/hyprpaper.conf"
DEFAULT_WALLPAPER_NAME="crimson_black_wallpaper.png"
DEFAULT_WALLPAPER_PATH="$WALLPAPER_DIR_TARGET/$DEFAULT_WALLPAPER_NAME"
USER_WALLPAPER_PATH=""

mkdir -p "$WALLPAPER_DIR_TARGET"

USER_WALLPAPER_PATH="$DEFAULT_WALLPAPER_PATH"
echo "INFO: Using default wallpaper: $USER_WALLPAPER_PATH for Hyprpaper."

prepare_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"
cat << EOF > "$HYPRPAPER_CONF_FILE"
preload = $USER_WALLPAPER_PATH
wallpaper = ,$USER_WALLPAPER_PATH
ipc = off
EOF
finish_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"
