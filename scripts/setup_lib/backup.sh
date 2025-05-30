#!/usr/bin/env bash
set -euo pipefail

_do_backup_item() {
    local target_config_path="$1"
    local backup_parent_dir="$2"

    if [ -e "$target_config_path" ]; then
        local TIMESTAMP
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        local SPECIFIC_BACKUP_DIR="${backup_parent_dir}_${TIMESTAMP}"
        mkdir -p "$SPECIFIC_BACKUP_DIR"
        local BASENAME
        BASENAME=$(basename "$target_config_path")
        echo "Backing up $target_config_path to $SPECIFIC_BACKUP_DIR/$BASENAME..."
        if mv "$target_config_path" "$SPECIFIC_BACKUP_DIR/$BASENAME"; then
            echo "Backup of $BASENAME successful."
        else
            echo "WARNING: Backup of $BASENAME failed."
        fi
    fi
}

handle_backup_process() {
    local components_to_backup=("$@")

    read -p "Overwrite configs in $CONFIG_TARGET_DIR/. Backup? (Y/n): " backup_choice
    backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')

    if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
        mkdir -p "$BACKUP_DIR_BASE"
        echo "Configs will be backed up to $BACKUP_DIR_BASE..."
        for component in "${components_to_backup[@]}"; do
            _do_backup_item "$CONFIG_TARGET_DIR/$component" "$BACKUP_DIR_BASE"
        done
    else
        echo "Skipping backup."
    fi
    echo ""
}
