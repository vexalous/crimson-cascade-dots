#!/usr/bin/env bash
set -euo pipefail


CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"

DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png"
WALLPAPER_TARGET_DIR="$CONFIG_TARGET_DIR/hypr/wallpaper"
USER_HYPR_SCRIPTS_DIR="$CONFIG_TARGET_DIR/hypr/scripts"

DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR=""

source "$(dirname "$0")/scripts/setup_lib/ui.sh"
source "$(dirname "$0")/scripts/setup_lib/dependencies.sh"
source "$(dirname "$0")/scripts/setup_lib/backup.sh"
source "$(dirname "$0")/scripts/setup_lib/fs_ops.sh"
source "$(dirname "$0")/scripts/setup_lib/git_ops.sh"

print_header

read -r DOTFILES_SOURCE_DIR TEMP_CLONE_DIR < <(determine_source_dir)
HYPRPAPER_SCRIPT_PATH="$DOTFILES_SOURCE_DIR/scripts/config/hyprpaper.sh"

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
    echo "Default wallpaper '$DEFAULT_WALLPAPER_FILE' copied to $WALLPAPER_TARGET_DIR."
else
    echo "Warning: Default wallpaper file '$DEFAULT_WALLPAPER_FILE' not found in '$DOTFILES_SOURCE_DIR'."
fi

echo "Copying Configuration Files from $DOTFILES_SOURCE_DIR ..."
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "hypr" "Hyprland"

echo "Copying hyprpaper.sh to user's Hyprland scripts directory..."
mkdir -p "$USER_HYPR_SCRIPTS_DIR" # Ensure target directory exists
if [ -f "$HYPRPAPER_SCRIPT_PATH" ]; then
    cp "$HYPRPAPER_SCRIPT_PATH" "$USER_HYPR_SCRIPTS_DIR/hyprpaper.sh"
    echo "hyprpaper.sh copied to $USER_HYPR_SCRIPTS_DIR."
else
    echo "Warning: Source hyprpaper.sh script not found at '$HYPRPAPER_SCRIPT_PATH'. Cannot copy to scripts directory."
fi

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

# Configure hyprpaper: Generate hyprpaper.conf.
# This script ensures the correct wallpaper path (default or user-defined) is set in hyprpaper.conf.
# It needs to run before hyprpaper daemon is (re)started to apply the latest settings.
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

echo "Managing hyprpaper daemon..."
if pgrep -x hyprpaper > /dev/null; then
    echo "Attempting to stop existing hyprpaper process..."
    if killall hyprpaper; then
        echo "hyprpaper process stopped."
        sleep 1 # Give it a moment to fully terminate
    else
        echo "Warning: killall hyprpaper command failed. Proceeding with caution."
        # Consider if further action is needed here, e.g. pkill or error
    fi
else
    echo "No existing hyprpaper process found."
fi

echo "Attempting to start hyprpaper daemon in background..."
if hyprpaper &> /dev/null; then # Start in background, suppress output for cleaner logs unless error
    # Check if hyprpaper started successfully
    # We can't easily get the exit code of a background process directly in a simple way.
    # A common approach is to check if the process exists shortly after starting.
    sleep 0.5 # Give it a moment to launch
    if pgrep -x hyprpaper > /dev/null; then
        echo "hyprpaper daemon started successfully in background."
    else
        echo "Error: hyprpaper daemon may not have started correctly. Please check manually."
    fi
else
    # This 'else' block for 'if hyprpaper &' might not be hit if hyprpaper itself forks and exits immediately.
    # The pgrep check above is more reliable for background processes.
    echo "Error: Failed to execute 'hyprpaper &' command. hyprpaper may not have started."
fi

echo "--------------------------------------------------------------------"
echo "Crimson Cascade Dotfiles setup process finished."
echo "LOG OUT and LOG BACK IN for all changes to take effect."
echo "--------------------------------------------------------------------"
