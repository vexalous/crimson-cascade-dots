#!/usr/bin/env bash
set -euo pipefail


CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"

readonly DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png"
readonly WALLPAPER_TARGET_DIR="$CONFIG_TARGET_DIR/hypr/wallpaper"
readonly USER_HYPR_SCRIPTS_DIR="$CONFIG_TARGET_DIR/hypr/scripts"

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
copy_single_file "$DEFAULT_WALLPAPER_FILE" "hypr/wallpaper/$DEFAULT_WALLPAPER_FILE" \
    "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Default wallpaper"

echo "Copying Configuration Files from $DOTFILES_SOURCE_DIR ..."
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "hypr" "Hyprland"

echo "Installing hyprpaper.sh to user's Hyprland scripts directory..."
copy_single_file "scripts/config/hyprpaper.sh" "hypr/scripts/hyprpaper.sh" \
    "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Hyprpaper script"

echo "Ensuring HYPR_SCRIPTS_DIR and CONFIG_TARGET_DIR are set in Hyprland environment configuration..."
target_env_file="$CONFIG_TARGET_DIR/hypr/conf/env.conf"
scripts_dir_value="$CONFIG_TARGET_DIR/hypr/scripts" # This will expand to /home/user/.config/hypr/scripts
config_target_dir_value="$CONFIG_TARGET_DIR" # This will expand to /home/user/.config
env_line_to_set="env = HYPR_SCRIPTS_DIR,$scripts_dir_value"
config_env_line_to_set="env = CONFIG_TARGET_DIR,$config_target_dir_value"
env_line_pattern_base="env = HYPR_SCRIPTS_DIR,"
config_env_line_pattern_base="env = CONFIG_TARGET_DIR,"
comment_env_line_pattern_base="# *env = HYPR_SCRIPTS_DIR,"
comment_config_env_line_pattern_base="# *env = CONFIG_TARGET_DIR,"

if [ -f "$target_env_file" ]; then
    # Remove existing definitions (commented or active)
    sed -i "/^ *${env_line_pattern_base}/d" "$target_env_file"
    sed -i "/^ *${comment_env_line_pattern_base}/d" "$target_env_file"
    sed -i "/^ *${config_env_line_pattern_base}/d" "$target_env_file"
    sed -i "/^ *${comment_config_env_line_pattern_base}/d" "$target_env_file"

    # Add the correct definitions
    echo "$env_line_to_set" >> "$target_env_file"
    echo "$config_env_line_to_set" >> "$target_env_file"
    echo "HYPR_SCRIPTS_DIR and CONFIG_TARGET_DIR set in $target_env_file"
else
    echo "Warning: $target_env_file not found. Cannot set HYPR_SCRIPTS_DIR and CONFIG_TARGET_DIR."
fi

# Configure hyprpaper: Generate hyprpaper.conf.
# This script ensures the correct wallpaper path (default or user-defined) is set in hyprpaper.conf.
# It needs to run before hyprpaper daemon is (re)started to apply the latest settings.
echo "Configuring hyprpaper using the script in user's config directory..."
local_hyprpaper_script="$USER_HYPR_SCRIPTS_DIR/hyprpaper.sh" # Path to the copied script

if [ -f "$local_hyprpaper_script" ]; then
    chmod +x "$local_hyprpaper_script"
    echo "Executing hyprpaper configuration script: $local_hyprpaper_script"
    # Export CONFIG_TARGET_DIR so the hyprpaper script can access it
    export CONFIG_TARGET_DIR
    "$local_hyprpaper_script"
else
    echo "Warning: hyprpaper script not found at $local_hyprpaper_script. Wallpaper config may be incorrect."
fi

copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "waybar" "Waybar"

echo "Managing waybar process..."
if command -v waybar > /dev/null 2>&1; then
    if pgrep -x waybar > /dev/null; then
        echo "Attempting to stop existing waybar process..."
        if killall waybar; then
            echo "waybar process stopped."
            sleep 1 # Give it a moment to fully terminate
        else
            echo "Warning: killall waybar command failed. Proceeding with caution."
        fi
    else
        echo "No existing waybar process found."
    fi

    echo "Attempting to start waybar in background..."
    if waybar &> /dev/null & then
        # Process successfully launched into background
        sleep 0.5 # Give it a moment to launch
        if pgrep -x waybar > /dev/null; then
            echo "waybar started successfully in background."
        else
            echo "Error: waybar was launched but seems to have exited or failed to start. Please check manually."
        fi
    else
        echo "Error: Failed to execute 'waybar' command. waybar may not have started."
    fi
else
    echo "Warning: waybar command not found. Please install waybar to use the status bar."
fi

copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Alacritty"

cleanup_temp_dir "$TEMP_CLONE_DIR"

echo "Managing hyprpaper daemon..."
if command -v hyprpaper > /dev/null 2>&1; then
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
    if hyprpaper &> /dev/null & then # Corrected line: added trailing '&'
        # Process successfully launched into background (shell command itself succeeded)
        sleep 0.5 # Give it a moment to launch
        if pgrep -x hyprpaper > /dev/null; then
            echo "hyprpaper daemon started successfully in background."
        else
            echo "Error: hyprpaper daemon was launched but seems to have exited or failed to start. Please check manually."
        fi
    else
        # This else block would typically be hit if the command 'hyprpaper' itself is not found or immediately fails before backgrounding.
        echo "Error: Failed to execute 'hyprpaper' command. hyprpaper may not have started."
    fi
else
    echo "Warning: hyprpaper command not found. Please install hyprpaper to use wallpaper functionality."
fi

echo "--------------------------------------------------------------------"
echo "Crimson Cascade Dotfiles setup process finished."
echo ""
echo "The following services have been started:"
echo "  - hyprpaper (wallpaper daemon)"
echo "  - waybar (status bar)"
echo ""
echo "If you're running this setup outside of a Hyprland session,"
echo "LOG OUT and LOG BACK IN for all changes to take effect."
echo "--------------------------------------------------------------------"
