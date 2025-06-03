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
    echo " Crimson Cascade Dotfiles - Forceful Setup v4.1 (Unattended)"
    echo "--------------------------------------------------------------------"
    echo "INFO: This script will forcefully replace configurations."
    echo "Existing configurations will be backed up mandatorily."
    echo ""
}

ensure_base_directories() {
    echo "Ensuring base target and backup directories are accessible..."
    if ! mkdir -p "$CONFIG_TARGET_DIR"; then
        echo "CRITICAL ERROR: Could not create or access target configuration directory: $CONFIG_TARGET_DIR"
        echo "Please check permissions. If this directory requires root, run the script with sudo."
        exit 1
    fi
    echo "Target configuration directory '$CONFIG_TARGET_DIR' is accessible."

    if ! mkdir -p "$BACKUP_DIR_BASE"; then
        echo "CRITICAL ERROR: Could not create or access backup base directory: $BACKUP_DIR_BASE"
        echo "Please check permissions."
        exit 1
    fi
    echo "Backup base directory '$BACKUP_DIR_BASE' is accessible."
    echo ""
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
            echo "WARNING: 'git pull' failed. Using local state of the repository."
        else
            echo "Repository updated successfully."
        fi
    else
        echo "Not in a recognized dotfiles Git repository or key file (wallpaper) missing. Cloning fresh..."
        TEMP_CLONE_DIR=$(mktemp -d -t "${REPO_NAME}_XXXXXX")
        if [ -z "$TEMP_CLONE_DIR" ] || [ ! -d "$TEMP_CLONE_DIR" ]; then # Check mktemp success
            echo "ERROR: Failed to create temporary directory for cloning."
            exit 1
        fi
        git clone --depth 1 "$GIT_REPO_URL" "$TEMP_CLONE_DIR"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to clone $GIT_REPO_URL to $TEMP_CLONE_DIR."
            rm -rf "$TEMP_CLONE_DIR" # Clean up
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
    echo "INFO: Existing configurations in $CONFIG_TARGET_DIR will be MANDATORILY backed up before being overwritten."
    echo "Backing up existing configurations to $BACKUP_DIR_BASE..."
    # mkdir -p "$BACKUP_DIR_BASE" # Already ensured by ensure_base_directories

    local components_to_backup=("hypr" "waybar" "alacritty" "rofi") # Rofi backup included if dir exists

    for component in "${components_to_backup[@]}"; do
        local target_path="${CONFIG_TARGET_DIR}/${component}"
        if [ -e "$target_path" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            SPECIFIC_BACKUP_DIR_FOR_COMPONENT="${BACKUP_DIR_BASE}/${component}_${TIMESTAMP}"
            
            echo "Attempting to back up '$target_path' to '$SPECIFIC_BACKUP_DIR_FOR_COMPONENT'..."
            # Ensure the specific component backup dir can be created
            if ! mkdir -p "$SPECIFIC_BACKUP_DIR_FOR_COMPONENT"; then
                echo "WARNING: Failed to create directory $SPECIFIC_BACKUP_DIR_FOR_COMPONENT for backing up '$component'."
                echo "WARNING: '$component' at '$target_path' might be overwritten without backup. Skipping backup for this component."
                continue # Skip trying to mv this component
            fi

            if mv "$target_path" "$SPECIFIC_BACKUP_DIR_FOR_COMPONENT/"; then
                echo "Backup of '$component' successful to '$SPECIFIC_BACKUP_DIR_FOR_COMPONENT'."
            else
                echo "WARNING: Backup of '$component' FAILED (mv operation failed). '$target_path' might be overwritten."
                # If mv fails, force_copy_content will attempt to rm -rf it.
            fi
        else
            echo "No existing '$target_path' found to back up for component '${component}'."
        fi
    done
    echo "Backup process finished."
    echo ""
}

force_copy_content() {
    local source_relative_path_in_repo="$1" 
    local target_relative_path_in_config="$2" 
    local display_name="$3"                

    local full_source_path="${DOTFILES_SOURCE_DIR}/${source_relative_path_in_repo}"
    local full_target_path="${CONFIG_TARGET_DIR}/${target_relative_path_in_config}"

    echo "--- Forcefully processing ${display_name} ---"
    # echo "DEBUG: Source Path to check: '${full_source_path}'" # Uncomment for more verbosity
    # echo "DEBUG: Target Path to create/replace: '${full_target_path}'" # Uncomment for more verbosity

    if [ ! -e "${full_source_path}" ]; then
        echo "ERROR: Source NOT FOUND: '${full_source_path}'. CANNOT COPY ${display_name}."
        echo "-------------------------------------------"
        return 1
    fi

    # Ensure parent directory of the target item exists
    local target_parent_dir
    target_parent_dir=$(dirname "${full_target_path}")
    if ! mkdir -p "${target_parent_dir}"; then
        echo "ERROR: Failed to create parent directory '${target_parent_dir}' for ${display_name}."
        echo "Check permissions or path validity."
        echo "-------------------------------------------"
        return 1
    fi

    if [ -e "${full_target_path}" ]; then
        echo "Removing existing target: '${full_target_path}'..."
        if ! rm -rf "${full_target_path}"; then # Added check for rm failure
            echo "ERROR: Failed to remove existing '${full_target_path}'. Permissions issue or target is busy?"
            echo "Skipping copy for ${display_name} due to removal failure."
            echo "-------------------------------------------"
            return 1
        fi
    fi

    echo "Copying '${full_source_path}' to '${full_target_path}'..."
    if [ -d "${full_source_path}" ]; then
        cp -rT "${full_source_path}" "${full_target_path}"
    else
        cp -f "${full_source_path}" "${full_target_path}"
    fi

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to copy '${full_source_path}' to '${full_target_path}'."
        echo "Possible reasons: disk full, permissions, source/target issues."
        echo "-------------------------------------------"
        return 1
    fi

    echo "${display_name} forcefully processed and copied to '${full_target_path}'."
    echo "-------------------------------------------"
}

# --- Main Script ---
print_header
ensure_base_directories # New function call
determine_source_dir
perform_backups # Now non-interactive

echo ">>> Starting UNCONDITIONAL forceful configuration copy process... <<<"
echo ">>> Using DOTFILES_SOURCE_DIR: ${DOTFILES_SOURCE_DIR} <<<"
echo ">>> Target base directory: ${CONFIG_TARGET_DIR} <<<"
echo ""

# --- Component/File Copying ---
force_copy_content "hypr" "hypr" "Hyprland"
force_copy_content "waybar" "waybar" "Waybar"
force_copy_content "alacritty/alacritty.toml" "alacritty/alacritty.toml" "Alacritty Config"

# ROFI: Backup for existing ~/.config/rofi is handled in perform_backups.
# If you have Rofi configs in your dotfiles repo (e.g., at 'rofi_configs_in_repo/'),
# add a line like this:
# force_copy_content "rofi_configs_in_repo" "rofi" "Rofi"


# --- Specific File Copies (Standalone files) ---
WALLPAPER_SOURCE_FILE_IN_REPO="crimson_black_wallpaper.png"
HYPR_WALLPAPER_TARGET_DIR="${CONFIG_TARGET_DIR}/hypr/wallpaper"

if [ -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}" ]; then
    echo "--- Forcefully copying Wallpaper ---"
    # echo "DEBUG: Wallpaper Source: '${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}'"
    # echo "DEBUG: Wallpaper Target Dir: '${HYPR_WALLPAPER_TARGET_DIR}/'"
    if ! mkdir -p "${HYPR_WALLPAPER_TARGET_DIR}"; then
        echo "ERROR: Failed to create wallpaper target directory '${HYPR_WALLPAPER_TARGET_DIR}'."
    else
        if cp -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}" "${HYPR_WALLPAPER_TARGET_DIR}/"; then
            echo "Wallpaper copied to ${HYPR_WALLPAPER_TARGET_DIR}/"
        else
            echo "ERROR: Failed to copy wallpaper to ${HYPR_WALLPAPER_TARGET_DIR}/."
        fi
    fi
    echo "-------------------------------------------"
else
    echo "WARNING: Wallpaper source '${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE_IN_REPO}' not found."
    echo "-------------------------------------------"
fi

HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO="scripts/config/hyprpaper.sh"
HYPRPAPER_SCRIPT_TARGET_FULL_PATH="${CONFIG_TARGET_DIR}/hypr/scripts/hyprpaper.sh"

if [ -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}" ]; then
    echo "--- Forcefully copying Hyprpaper script ---"
    # echo "DEBUG: Hyprpaper Script Source: '${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}'"
    # echo "DEBUG: Hyprpaper Script Target: '${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}'"
    HYPRPAPER_SCRIPT_TARGET_DIR=$(dirname "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}")
    if ! mkdir -p "$HYPRPAPER_SCRIPT_TARGET_DIR"; then
        echo "ERROR: Failed to create Hyprpaper script target directory '${HYPRPAPER_SCRIPT_TARGET_DIR}'."
    else
        if cp -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH_IN_REPO}" "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}"; then
            chmod +x "${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}"
            echo "Hyprpaper script copied to '${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}' and made executable."
        else
            echo "ERROR: Failed to copy Hyprpaper script to '${HYPRPAPER_SCRIPT_TARGET_FULL_PATH}'."
        fi
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
echo " If you encountered permission errors, you may need to run this"
echo " script with 'sudo'."
echo "--------------------------------------------------------------------"

exit 0
