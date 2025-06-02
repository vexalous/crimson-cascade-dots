#!/bin/bash

# --- Configuration ---
CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
REPO_NAME="crimson-cascade-dots"
DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR=""

# --- Helper Functions ---
print_header() {
    echo "--------------------------------------------------------------------"
    echo " Crimson Cascade Dotfiles - Forceful Setup v4 (Based on Your Structure)"
    echo "--------------------------------------------------------------------"
}

determine_source_dir() {
    echo "Determining dotfiles source..."
    # Check for a .git directory and a known root file (crimson_black_wallpaper.png)
    # to confirm we are in the correct repository root. This helps prevent running
    # the script from an incorrect location if it was partially copied.
    if [ -d ".git" ] && [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/crimson_black_wallpaper.png" ]; then
        DOTFILES_SOURCE_DIR="$(git rev-parse --show-toplevel)"
        echo "Running from local Git repository: $DOTFILES_SOURCE_DIR"
        echo "Attempting to update repository..."
        (
            cd "$DOTFILES_SOURCE_DIR" && \
            git pull origin main # Or your default branch
        )
        if [ $? -ne 0 ]; then
            echo "WARNING: 'git pull' failed. Using local state."
        else
            echo "Repository updated."
        fi
    else
        echo "Not in a recognized dotfiles Git repository or key file (wallpaper) missing. Cloning fresh..."
        TEMP_CLONE_DIR=$(mktemp -d -t "${REPO_NAME}_XXXXXX")
        git clone --depth 1 "$GIT_REPO_URL" "$TEMP_CLONE_DIR"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to clone $GIT_REPO_URL to $TEMP_CLONE_DIR."
            rm -rf "$TEMP_CLONE_DIR"
            exit 1
        fi
        DOTFILES_SOURCE_DIR="$TEMP_CLONE_DIR"
        echo "Repository cloned to temporary directory: $DOTFILES_SOURCE_DIR"
    fi
    echo ""
    echo "FINAL DOTFILES SOURCE DIR: $DOTFILES_SOURCE_DIR" 
    if [ ! -d "$DOTFILES_SOURCE_DIR" ]; then
        echo "CRITICAL ERROR: DOTFILES_SOURCE_DIR is not a valid directory: $DOTFILES_SOURCE_DIR"
        exit 1
    fi
    echo ""
}

perform_backups() {
    read -p "Overwrite existing configurations in $CONFIG_TARGET_DIR? Backup first? (Y/n): " backup_choice
    backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')

    if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
        echo "Backing up existing configurations to $BACKUP_DIR_BASE..."
        mkdir -p "$BACKUP_DIR_BASE"
        
        # Rofi is still in this list; if ~/.config/rofi exists, it will be backed up.
        # If not, the script will just note it wasn't found for backup.
        local components_to_backup=("hypr" "waybar" "alacritty" "rofi") 
        
        for component in "${components_to_backup[@]}"; do
            local target_path="${CONFIG_TARGET_DIR}/${component}"
            # Check if the target path exists (can be a file or directory)
            if [ -e "$target_path" ]; then 
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                SPECIFIC_BACKUP_DIR_FOR_COMPONENT="${BACKUP_DIR_BASE}/${component}_${TIMESTAMP}"
                mkdir -p "$SPECIFIC_BACKUP_DIR_FOR_COMPONENT"
                echo "Backing up '$target_path' to '$SPECIFIC_BACKUP_DIR_FOR_COMPONENT'..."
                if mv "$target_path" "$SPECIFIC_BACKUP_DIR_FOR_COMPONENT/"; then
                    echo "Backup of '$component' successful."
                else
                    echo "WARNING: Backup of '$component' FAILED. It might be overwritten."
                fi
            else
                echo "No existing '$target_path' found to back up for component '${component}'."
            fi
        done
        echo "Backup process finished."
    else
        echo "Skipping backup."
    fi
    echo ""
}

force_copy_content() {
    local source_relative_path_in_repo="$1" # Path to the source file/dir relative to DOTFILES_SOURCE_DIR
    local target_relative_path_in_config="$2" # Path to the target file/dir relative to CONFIG_TARGET_DIR
    local display_name="$3"                 # User-friendly name for logging

    # This function forcefully copies content. It will:
    # 1. Check if the source exists in the dotfiles repository.
    # 2. Create the parent directory for the target if it doesn't exist.
    # 3. If the target already exists, it will be REMOVED (rm -rf).
    # 4. Copy the source to the target location.
    #    - Uses 'cp -rT' for directories to copy contents directly into the target directory.
    #    - Uses 'cp -f' for files.

    local full_source_path="${DOTFILES_SOURCE_DIR}/${source_relative_path_in_repo}"
    local full_target_path="${CONFIG_TARGET_DIR}/${target_relative_path_in_config}"

    echo "--- Forcefully processing ${display_name} ---"
    echo "DEBUG: Source Path to check: '${full_source_path}'"
    echo "DEBUG: Target Path to create/replace: '${full_target_path}'"

    if [ ! -e "${full_source_path}" ]; then 
        echo "ERROR: Source NOT FOUND: '${full_source_path}'. CANNOT COPY ${display_name}."
        echo "-------------------------------------------"
        return 1 
    fi

    mkdir -p "$(dirname "${full_target_path}")" # Ensure parent of target exists

    if [ -e "${full_target_path}" ]; then 
        echo "Removing existing target: '${full_target_path}'..."
        rm -rf "${full_target_path}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to remove '${full_target_path}'. Permissions issue or target is busy?"
            echo "-------------------------------------------"
            return 1 # Stop this specific copy operation
        fi
    fi

    echo "Copying '${full_source_path}' to '${full_target_path}'..."
    if [ -d "${full_source_path}" ]; then
        # -r: recursive, -T: treat source as a normal file (useful when source is a dir,
        # ensures contents are copied into target_path, not source_dir as a subdir in target_path)
        cp -rT "${full_source_path}" "${full_target_path}" 
    else 
        # -f: force (overwrite if target exists, though we removed it already)
        cp -f "${full_source_path}" "${full_target_path}"
    fi
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to copy '${full_source_path}' to '${full_target_path}'."
        echo "-------------------------------------------"
        return 1 # Stop this specific copy operation
    fi
    
    echo "${display_name} forcefully processed and copied to '${full_target_path}'."
    echo "-------------------------------------------"
}

# --- Main Script ---
print_header
determine_source_dir 
perform_backups

echo ">>> Starting UNCONDITIONAL forceful configuration copy process... <<<"
echo ">>> Using DOTFILES_SOURCE_DIR: ${DOTFILES_SOURCE_DIR} <<<"
echo ">>> Target base directory: ${CONFIG_TARGET_DIR} <<<"
echo ""

# --- Component/File Copying ---
# Paths are based on the directory structure you provided.

# Source: ${DOTFILES_SOURCE_DIR}/hypr
# Target: ${CONFIG_TARGET_DIR}/hypr
force_copy_content "hypr" "hypr" "Hyprland"

# Source: ${DOTFILES_SOURCE_DIR}/waybar
# Target: ${CONFIG_TARGET_DIR}/waybar
force_copy_content "waybar" "waybar" "Waybar"

# Source: ${DOTFILES_SOURCE_DIR}/alacritty/alacritty.toml
# Target: ${CONFIG_TARGET_DIR}/alacritty/alacritty.toml
force_copy_content "alacritty/alacritty.toml" "alacritty/alacritty.toml" "Alacritty Config"

# ROFI HAS BEEN REMOVED as it's not in the provided root structure.
# If you have Rofi configs, provide the path within your dotfiles repo.
# For example, if it was actually in 'dotfiles_repo/my_rofi_configs/', you'd use:
# force_copy_content "my_rofi_configs" "rofi" "Rofi"


# --- Specific File Copies (Standalone files) ---
WALLPAPER_SOURCE_FILE_IN_REPO="crimson_black_wallpaper.png" # This is at the root of your repo
HYPR_WALLPAPER_TARGET_DIR="${CONFIG_TARGET_DIR}/hypr/wallpaper" 

if [ -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}" ]; then
    echo "--- Forcefully copying Wallpaper ---"
    echo "DEBUG: Wallpaper Source: '${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}'"
    echo "DEBUG: Wallpaper Target Dir: '${HYPR_WALLPAPER_TARGET_DIR}/'"
    mkdir -p "${HYPR_WALLPAPER_TARGET_DIR}"
    cp -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}" "${HYPR_WALLPAPER_TARGET_DIR}/"
    if [ $? -eq 0 ]; then
        echo "Wallpaper copied to ${HYPR_WALLPAPER_TARGET_DIR}/"
    else
        echo "ERROR: Failed to copy wallpaper."
    fi
    echo "-------------------------------------------"
else
    echo "WARNING: Wallpaper source '${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}' not found."
    echo "-------------------------------------------"
fi

# Hyprpaper script, located in scripts/config/ within your repo
HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO="scripts/config/hyprpaper.sh" 
HYPRPAPER_SCRIPT_TARGET_FULL_PATH="${CONFIG_TARGET_DIR}/hypr/scripts/hyprpaper.sh"

if [ -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}" ]; then
    echo "--- Forcefully copying Hyprpaper script ---"
    echo "DEBUG: Hyprpaper Script Source: '${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}'"
    echo "DEBUG: Hyprpaper Script Target: '${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}'"
    mkdir -p "$(dirname "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}")"
    cp -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}" "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}"
    if [ $? -eq 0 ]; then
        chmod +x "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}"
        echo "Hyprpaper script copied and made executable."
    else
        echo "ERROR: Failed to copy Hyprpaper script."
    fi
    echo "-------------------------------------------"
else
    echo "WARNING: Hyprpaper script source '${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}' not found."
    echo "This script path is based on 'scripts/config/' existing in your repo."
    echo "If hyprpaper.sh is elsewhere, please adjust the HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO variable."
    echo "-------------------------------------------"
fi

# --- Cleanup Temporary Directory ---
if [ -n "$TEMP_CLONE_DIR" ] && [ -d "$TEMP_CLONE_DIR" ]; then
    echo "Removing temporary clone directory: $TEMP_CLONE_DIR..."
    rm -rf "$TEMP_CLONE_DIR"
fi

echo ""
echo "--------------------------------------------------------------------"
echo " Crimson Cascade Dotfiles forceful setup process FINISHED."
echo " It is STRONGLY RECOMMENDED to LOG OUT and LOG BACK IN"
echo " for all changes to take full effect."
echo "--------------------------------------------------------------------"

exit 0
