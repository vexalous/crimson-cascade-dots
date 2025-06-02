#!/usr/bin/env bash
set -euo pipefail

_do_backup_item() {
    local target_config_path="$1" # Full path to the item to be backed up
    local backup_parent_dir="$2"  # Base directory where the timestamped backup folder for this item will be created

    # Check if the target path exists (can be a file or directory)
    if [ -e "$target_config_path" ]; then
        local TIMESTAMP
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        # Example: if backup_parent_dir is "/home/user/config_backups_crimson_cascade/hypr",
        # SPECIFIC_BACKUP_DIR becomes "/home/user/config_backups_crimson_cascade/hypr_20230101_123000".
        local SPECIFIC_BACKUP_DIR="${backup_parent_dir}_${TIMESTAMP}"
        mkdir -p "$SPECIFIC_BACKUP_DIR"
        local BASENAME
        BASENAME=$(basename "$target_config_path")
        echo "Backing up $target_config_path to $SPECIFIC_BACKUP_DIR/$BASENAME..."
        if mv "$target_config_path" "$SPECIFIC_BACKUP_DIR/$BASENAME"; then
            echo "Backup of $BASENAME successful."
        else
            echo "ERROR: Backup of $BASENAME to $SPECIFIC_BACKUP_DIR/$BASENAME failed." >&2
            # Critical error: If moving the original config fails, the script exits.
            # This prevents accidental data loss if the script were to proceed and overwrite.
            exit 1
        fi
    fi
}

# Handles the overall backup process for a list of components.
# Expects CONFIG_TARGET_DIR and BACKUP_DIR_BASE to be set in the calling environment.
# Arguments:
#   $@: An array of component names (e.g., "hypr", "alacritty") whose corresponding
#       directories/files under CONFIG_TARGET_DIR will be backed up.
handle_backup_process() {
    local components_to_backup=("$@") # Capture all arguments as an array of component names

    # CONFIG_TARGET_DIR and BACKUP_DIR_BASE are assumed to be global or exported.
    read -p "Overwrite configs in $CONFIG_TARGET_DIR/. Backup? (Y/n): " backup_choice
    backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')

    if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
        mkdir -p "$BACKUP_DIR_BASE" # Ensure the base backup directory exists
        echo "Configs will be backed up to $BACKUP_DIR_BASE..."
        for component in "${components_to_backup[@]}"; do
            # For each component, the backup will be in a sub-directory like:
            # $BACKUP_DIR_BASE/component_name_TIMESTAMP
            # Example: /home/user/config_backups_crimson_cascade/hypr_20230101_123000
            _do_backup_item "$CONFIG_TARGET_DIR/$component" "$BACKUP_DIR_BASE/$component"
        done
    else
        echo "Skipping backup."
    fi
    echo ""
}
