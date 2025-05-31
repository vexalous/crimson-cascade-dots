#!/usr/bin/env bash
set -euo pipefail

# This setup script installs dotfiles by copying pre-defined configuration files
# directly from this repository into the appropriate ~/.config subdirectories.
#
# The scripts located in the 'scripts/config/' directory are primarily intended
# for developer use. They serve as generators or templates to help create/update
# the static configuration files stored within the repository (e.g., in 'hypr/', 'waybar/', 'alacritty/').
# These generator scripts are NOT executed during the user-facing setup process
# handled by this setup.sh script.

CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"

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

echo "Copying Configuration Files from $DOTFILES_SOURCE_DIR ..."
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "hypr" "Hyprland"
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "waybar" "Waybar"
copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Alacritty"

cleanup_temp_dir "$TEMP_CLONE_DIR"

echo "--------------------------------------------------------------------"
echo "Crimson Cascade Dotfiles setup process finished."
echo "LOG OUT and LOG BACK IN for all changes to take effect."
echo "--------------------------------------------------------------------"
