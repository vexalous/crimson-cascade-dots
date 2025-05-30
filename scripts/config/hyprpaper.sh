#!/usr/bin/env bash
set -euo pipefail
HYPRPAPER_CONF_FILE="$CONFIG_TARGET_DIR/hypr/hyprpaper.conf"
DEFAULT_WALLPAPER_NAME="crimson_black_wallpaper.png"
DEFAULT_WALLPAPER_PATH="$WALLPAPER_DIR_TARGET/$DEFAULT_WALLPAPER_NAME"
USER_WALLPAPER_PATH=""
echo ""
echo "--- Wallpaper Configuration (Hyprpaper) ---"
mkdir -p "$WALLPAPER_DIR_TARGET"
echo "Default wallpaper: '$DEFAULT_WALLPAPER_NAME' (expected in $WALLPAPER_DIR_TARGET)."
read -p "Use default wallpaper path ($DEFAULT_WALLPAPER_PATH)? (Y/n): " use_default
use_default=$(echo "$use_default" | tr '[:upper:]' '[:lower:]')
if [[ "$use_default" == "n" || "$use_default" == "no" ]]; then
    read -e -p "Enter FULL path to your desired wallpaper image: " custom_path
    if [ -f "$custom_path" ]; then USER_WALLPAPER_PATH="$custom_path"; else
        echo "WARNING: Custom path '$custom_path' not found. Defaulting."; USER_WALLPAPER_PATH="$DEFAULT_WALLPAPER_PATH"; fi
else USER_WALLPAPER_PATH="$DEFAULT_WALLPAPER_PATH"; fi
echo "Using wallpaper: $USER_WALLPAPER_PATH for Hyprpaper."

prepare_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"
cat << EOF > "$HYPRPAPER_CONF_FILE"
preload = $USER_WALLPAPER_PATH
wallpaper = ,$USER_WALLPAPER_PATH
ipc = off
EOF
finish_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"
