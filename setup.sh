#!/usr/bin/env bash
set -euo pipefail


CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"

DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png"
WALLPAPER_TARGET_DIR="$CONFIG_TARGET_DIR/hypr/wallpaper"
HYPRPAPER_SCRIPT_PATH="$DOTFILES_SOURCE_DIR/scripts/config/hyprpaper.sh"

DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR=""

source "$(dirname "$0")/scripts/setup_lib/ui.sh"
source "$(dirname "$0")/scripts/setup_lib/dependencies.sh"
source "$(dirname "$0")/scripts/setup_lib/backup.sh"
source "$(dirname "$0")/scripts/setup_lib/fs_ops.sh"
source "$(dirname "$0")/scripts/setup_lib/git_ops.sh"

print_header

read -r DOTFILES_SOURCE_DIR TEMP_CLONE_DIR < <(determine_source_dir)

if [ -n "$TEMP_CLONE_DIR" ]; then
    verify_core_dependencies
fi


declare -a components_to_backup=("hypr" "waybar" "alacritty" "rofi")
handle_backup_process "${components_to_backup[@]}"

declare -a target_dirs_to_ensure=(
    "hypr/conf" "hypr/scripts"
    "waybar" "alacritty" "rofi"
)
ensure_target_dirs "$CONFIG_TARGET_DIR" "${target_dirs_to_ensure[@]}"

echo "Setting up default wallpaper..."
mkdir -p "$WALLPAPER_TARGET_DIR"
if [ -f "$DOTFILES_SOURCE_DIR/$DEFAULT_WALLPAPER_FILE" ]; then
    cp "$DOTFILES_SOURCE_DIR/$DEFAULT_WALLPAPER_FILE" "$WALLPAPER_TARGET_DIR/"
    echo "Default wallpaper copied to $WALLPAPER_TARGET_DIR."
else
    echo "Warning: Default wallpaper file '$DEFAULT_WALLPAPER_FILE' not found in '$DOTFILES_SOURCE_DIR'."
fi

echo "Copying Configuration Files from $DOTFILES_SOURCE_DIR ..."
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "hypr" "Hyprland"

echo "Ensuring HYPR_SCRIPTS_DIR is set in Hyprland environment configuration..."
target_env_file="$CONFIG_TARGET_DIR/hypr/conf/env.conf"
scripts_dir_value="$CONFIG_TARGET_DIR/hypr/scripts" # This will expand to /home/user/.config/hypr/scripts
env_line_to_set="env = HYPR_SCRIPTS_DIR,$scripts_dir_value"
env_line_pattern_base="env = HYPR_SCRIPTS_DIR,"
comment_env_line_pattern_base="# *env = HYPR_SCRIPTS_DIR,"

if [ -f "$target_env_file" ]; then
    # Remove existing definitions (commented or active)
    sed -i "/^ *\$env_line_pattern_base/d" "$target_env_file"
    sed -i "/^ *\$comment_env_line_pattern_base/d" "$target_env_file"

    # Add the correct definition
    echo "$env_line_to_set" >> "$target_env_file"
    echo "HYPR_SCRIPTS_DIR set in $target_env_file"
else
    echo "Warning: $target_env_file not found. Cannot set HYPR_SCRIPTS_DIR."
fi

echo "Configuring hyprpaper..."
if [ -f "$HYPRPAPER_SCRIPT_PATH" ]; then
    chmod +x "$HYPRPAPER_SCRIPT_PATH"
    echo "Executing hyprpaper configuration script: $HYPRPAPER_SCRIPT_PATH"
    "$HYPRPAPER_SCRIPT_PATH"
else
    echo "Warning: hyprpaper configuration script not found at $HYPRPAPER_SCRIPT_PATH"
fi

copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "waybar" "Waybar"
copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Alacritty"

cleanup_temp_dir "$TEMP_CLONE_DIR"

echo "Starting hyprpaper daemon..."
killall hyprpaper || true
hyprpaper &
echo "hyprpaper started in background."

echo "--------------------------------------------------------------------"
echo "Crimson Cascade Dotfiles setup process finished."
echo "LOG OUT and LOG BACK IN for all changes to take effect."
echo "--------------------------------------------------------------------"
