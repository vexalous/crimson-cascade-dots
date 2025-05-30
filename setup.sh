#!/usr/bin/env bash
set -euo pipefail

CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"
DOTFILES_SOURCE_DIR=""

print_header() {
    echo "--------------------------------------------------------------------"
    echo " Crimson Cascade Dotfiles Setup"
    echo "--------------------------------------------------------------------"
}

prompt_dependencies() {
    echo "Ensure core dependencies are installed."
    read -p "Are core dependencies installed? (y/N): " deps_installed
    deps_installed=$(echo "$deps_installed" | tr '[:upper:]' '[:lower:]')
    if [[ "$deps_installed" != "y" && "$deps_installed" != "yes" ]]; then
        echo "Please install dependencies and re-run."
        exit 1
    fi
    echo ""
}

do_backup() {
    local target_config_path="$1"; local backup_parent_dir="$2"
    if [ -e "$target_config_path" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S); SPECIFIC_BACKUP_DIR="${backup_parent_dir}_${TIMESTAMP}"
        mkdir -p "$SPECIFIC_BACKUP_DIR"; BASENAME=$(basename "$target_config_path")
        echo "Backing up $target_config_path to $SPECIFIC_BACKUP_DIR/$BASENAME..."
        if mv "$target_config_path" "$SPECIFIC_BACKUP_DIR/$BASENAME"; then echo "Backup of $BASENAME successful."; else echo "WARNING: Backup of $BASENAME failed."; fi
    fi
}

copy_component() {
    local source_base_dir="$1"; local target_base_dir="$2"; local component_rel_path="$3"; local component_name_for_msg="$4"
    local full_source_path="$source_base_dir/$component_rel_path"; local full_target_path="$target_base_dir/$component_rel_path"
    local target_dir=$(dirname "$full_target_path")
    if [ ! -e "$full_source_path" ]; then echo "WARNING: Source $full_source_path not found. Skipping $component_name_for_msg."; return 1; fi
    echo "Processing $component_name_for_msg..."
    mkdir -p "$target_dir"
    if [ -d "$full_source_path" ]; then mkdir -p "$full_target_path"; cp -rT "$full_source_path/" "$full_target_path/"; else cp "$full_source_path" "$full_target_path"; fi
    if [ $? -eq 0 ]; then
        echo "$component_name_for_msg files copied to $full_target_path."
        if [ "$component_name_for_msg" == "Hyprland" ] && [ -d "$full_target_path/scripts" ]; then chmod +x $full_target_path/scripts/*.sh; fi
    else echo "ERROR: Failed to copy $component_name_for_msg from $full_source_path."; fi; echo ""
}

copy_single_file() {
    local source_file_rel_path="$1"; local target_file_rel_path="$2"; local source_base_dir="$3"; local target_base_dir="$4"; local component_name_for_msg="$5"
    local full_source_path="$source_base_dir/$source_file_rel_path"; local full_target_path="$target_base_dir/$target_file_rel_path"
    local target_dir=$(dirname "$full_target_path")
    if [ -f "$full_source_path" ]; then
        echo "Copying $component_name_for_msg file..."
        mkdir -p "$target_dir"; cp "$full_source_path" "$full_target_path"
        if [ $? -eq 0 ]; then echo "$component_name_for_msg file copied."; else echo "ERROR: Failed to copy $component_name_for_msg file."; fi
    else echo "WARNING: Source '$full_source_path' not found. $component_name_for_msg config not copied."; fi; echo ""
}

print_header
TEMP_CLONE_DIR=""

if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
    echo "Running from Git repository. Attempting to update..."
    DOTFILES_SOURCE_DIR="$(git rev-parse --show-toplevel)"
    git -C "$DOTFILES_SOURCE_DIR" pull origin main
    if [ $? -ne 0 ]; then echo "ERROR: 'git pull' failed."; exit 1; fi
    echo "Repository updated from $DOTFILES_SOURCE_DIR."
else
    echo "Not in a recognized local dotfiles Git repository. Cloning fresh..."
    TEMP_CLONE_DIR=$(mktemp -d -t ${REPO_NAME}_XXXXXX)
    git clone --depth 1 "$GIT_REPO_URL" "$TEMP_CLONE_DIR"
    if [ $? -ne 0 ]; then echo "ERROR: Failed to clone $GIT_REPO_URL."; rm -rf "$TEMP_CLONE_DIR"; exit 1; fi
    DOTFILES_SOURCE_DIR="$TEMP_CLONE_DIR"
    echo "Repository cloned to $DOTFILES_SOURCE_DIR for this run."
    prompt_dependencies
fi
echo ""

read -p "Overwrite configs in $CONFIG_TARGET_DIR/. Backup? (Y/n): " backup_choice
backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')
DO_BACKUP=false
if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
    DO_BACKUP=true; mkdir -p "$BACKUP_DIR_BASE"; echo "Configs will be backed up to $BACKUP_DIR_BASE..."
else echo "Skipping backup."; fi; echo ""

if $DO_BACKUP; then
    do_backup "$CONFIG_TARGET_DIR/hypr" "$BACKUP_DIR_BASE"
    do_backup "$CONFIG_TARGET_DIR/waybar" "$BACKUP_DIR_BASE"
    do_backup "$CONFIG_TARGET_DIR/alacritty" "$BACKUP_DIR_BASE"
    do_backup "$CONFIG_TARGET_DIR/rofi" "$BACKUP_DIR_BASE"
fi

echo "Ensuring target directories in $CONFIG_TARGET_DIR/ ..."
mkdir -p "$CONFIG_TARGET_DIR/hypr/conf" "$CONFIG_TARGET_DIR/hypr/scripts" \
           "$CONFIG_TARGET_DIR/waybar" "$CONFIG_TARGET_DIR/alacritty" "$CONFIG_TARGET_DIR/rofi"
echo "Target directories ensured."
echo ""

echo "Copying Configuration Files from $DOTFILES_SOURCE_DIR ..."
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "hypr" "Hyprland"
copy_component "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "waybar" "Waybar"
copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" "$DOTFILES_SOURCE_DIR" "$CONFIG_TARGET_DIR" "Alacritty"

if [ -n "$TEMP_CLONE_DIR" ] && [ -d "$TEMP_CLONE_DIR" ]; then
    echo "Removing temporary clone directory $TEMP_CLONE_DIR..."
    rm -rf "$TEMP_CLONE_DIR"
fi

echo "--------------------------------------------------------------------"
echo "Crimson Cascade Dotfiles setup process finished."
echo "LOG OUT and LOG BACK IN for all changes to take effect."
echo "--------------------------------------------------------------------"
