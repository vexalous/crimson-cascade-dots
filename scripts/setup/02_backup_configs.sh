#!/bin/bash

_do_backup_internal_v2() {
    local target_config_path="$1" 
    local backup_parent_dir="$2"
    local component_name_for_msg="$3"

    if [ ! -e "$target_config_path" ] && [ ! -L "$target_config_path" ]; then
        echo "No existing configuration for $component_name_for_msg found at $target_config_path to back up."
        return
    fi
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SPECIFIC_BACKUP_SUBDIR="${backup_parent_dir}/${component_name_for_msg}_${TIMESTAMP}"
    mkdir -p "$SPECIFIC_BACKUP_SUBDIR"
    
    echo "Backing up existing $target_config_path to $SPECIFIC_BACKUP_SUBDIR ..."
    if mv "$target_config_path" "$SPECIFIC_BACKUP_SUBDIR/"; then 
        echo "Backup of $component_name_for_msg successful."
    else 
        echo "WARNING: Backup of $component_name_for_msg failed. It might have been a broken symlink or permission issue."
    fi
}

echo "--- Backing Up Existing Configurations ---"
read -p "This will attempt to backup existing configs from $CONFIG_TARGET_DIR/. Backup? (Y/n): " backup_choice
backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')

if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
    if [ ! -d "$BACKUP_DIR_BASE" ]; then
        mkdir -p "$BACKUP_DIR_BASE"
        echo "Created base backup directory: $BACKUP_DIR_BASE"
    fi
    echo "Configs will be backed up into subdirectories within $BACKUP_DIR_BASE..."

    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/hypr" "$BACKUP_DIR_BASE" "hypr"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/waybar" "$BACKUP_DIR_BASE" "waybar"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/alacritty" "$BACKUP_DIR_BASE" "alacritty"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/rofi" "$BACKUP_DIR_BASE" "rofi"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/mako" "$BACKUP_DIR_BASE" "mako"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/swaylock" "$BACKUP_DIR_BASE" "swaylock"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/hyprpaper.conf" "$BACKUP_DIR_BASE" "hyprpaper_conf"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/Kvantum" "$BACKUP_DIR_BASE" "Kvantum"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/qt5ct" "$BACKUP_DIR_BASE" "qt5ct"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/qt6ct" "$BACKUP_DIR_BASE" "qt6ct"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/gtk-3.0" "$BACKUP_DIR_BASE" "gtk3_config"
    _do_backup_internal_v2 "$CONFIG_TARGET_DIR/gtk-4.0" "$BACKUP_DIR_BASE" "gtk4_config"
    
    echo "Backup process finished."
else
    echo "Skipping backup of existing configurations."
fi
echo ""
