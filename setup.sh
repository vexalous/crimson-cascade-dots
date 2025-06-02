#!/bin/bash

# --- Configuration ---
CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DIR_BASE="$HOME/config_backups_crimson_cascade"
GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git" # Your repo URL
REPO_NAME="crimson-cascade-dots" # Your repo name
DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR=""

# --- Helper Functions ---
print_header() {
    echo "--------------------------------------------------------------------"
    echo " Crimson Cascade Dotfiles - Forceful Setup"
    echo "--------------------------------------------------------------------"
}

determine_source_dir() {
    echo "Determining dotfiles source..."
    # Check if current directory is the git repo and contains 'hypr' (as a sanity check)
    if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
        DOTFILES_SOURCE_DIR="$(git rev-parse --show-toplevel)"
        echo "Running from local Git repository: $DOTFILES_SOURCE_DIR"
        echo "Attempting to update repository..."
        (cd "$DOTFILES_SOURCE_DIR" && git pull origin main) # Or your default branch
        if [ $? -ne 0 ]; then
            echo "WARNING: 'git pull' failed. Using local state."
        else
            echo "Repository updated."
        fi
    else
        echo "Not in a recognized dotfiles Git repository or 'hypr' dir missing. Cloning fresh..."
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
}

perform_backups() {
    read -p "Overwrite existing configurations in $CONFIG_TARGET_DIR? Backup first? (Y/n): " backup_choice
    backup_choice=$(echo "$backup_choice" | tr '[:upper:]' '[:lower:]')

    if [[ "$backup_choice" == "y" || "$backup_choice" == "" ]]; then
        echo "Backing up existing configurations to $BACKUP_DIR_BASE..."
        mkdir -p "$BACKUP_DIR_BASE"
        
        local components_to_backup=("hypr" "waybar" "alacritty" "rofi") # Add more as needed
        
        for component in "${components_to_backup[@]}"; do
            local target_path="${CONFIG_TARGET_DIR}/${component}"
            if [ -e "$target_path" ]; then # Check if file or directory exists
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
                echo "No existing '$target_path' found to back up."
            fi
        done
        echo "Backup process finished."
    else
        echo "Skipping backup."
    fi
    echo ""
}

# This function will DELETE the target component directory if it exists, then copy.
# For single files, it will just overwrite.
force_copy_content() {
    local source_relative_path="$1" # e.g., "hypr" or "alacritty/alacritty.toml"
    local display_name="$2"         # e.g., "Hyprland"

    local full_source_path="${DOTFILES_SOURCE_DIR}/${source_relative_path}"
    local full_target_path="${CONFIG_TARGET_DIR}/${source_relative_path}"

    echo "--- Forcefully processing ${display_name} ---"

    if [ ! -e "${full_source_path}" ]; then
        echo "ERROR: Source NOT FOUND: '${full_source_path}'. Skipping ${display_name}."
        echo "-------------------------------------------"
        return 1 # Critical error for this component
    fi

    # Ensure parent directory of the target exists
    mkdir -p "$(dirname "${full_target_path}")"

    # If target exists, remove it first for a clean copy (especially for directories)
    if [ -e "${full_target_path}" ]; then
        echo "Removing existing target: '${full_target_path}'..."
        rm -rf "${full_target_path}"
    fi

    echo "Copying '${full_source_path}' to '${full_target_path}'..."
    # For directories, `cp -rT` copies contents of source dir into target dir.
    # If target dir doesn't exist, it creates it.
    # If source is a file, `cp -f` overwrites.
    if [ -d "${full_source_path}" ]; then
        cp -rT "${full_source_path}" "${full_target_path}" # -T treats DEST as a normal file/dir
    else # It's a file
        cp -f "${full_source_path}" "${full_target_path}"
    fi
    
    echo "${display_name} forcefully processed."
    echo "-------------------------------------------"
}

# --- Main Script ---
print_header
determine_source_dir
perform_backups

echo ">>> Starting UNCONDITIONAL forceful configuration copy process... <<<"

# --- Component/File Copying ---
# For each component, specify its relative path in your dotfiles repo
# and a display name.

force_copy_content "hypr"       "Hyprland"
force_copy_content "waybar"     "Waybar"

# For Alacritty, assuming alacritty.toml is inside an 'alacritty' folder in your repo
force_copy_content "alacritty/alacritty.toml" "Alacritty Config"
# If alacritty is a full directory in your repo:
# force_copy_content "alacritty" "Alacritty"

# For Rofi, assuming rofi is a full directory in your repo
force_copy_content "rofi" "Rofi"
# If rofi is just a single config file (e.g., config.rasi inside a 'rofi' folder):
# force_copy_content "rofi/config.rasi" "Rofi Config"


# --- Specific File Copies (if not handled by component copies) ---
# Example: Wallpaper (if it's at the root of your repo and needs to go to a specific place)
# This assumes your 'hypr' component copy already created ~/.config/hypr/
WALLPAPER_SOURCE_FILE="crimson_black_wallpaper.png" # Name of wallpaper in DOTFILES_SOURCE_DIR root
HYPR_WALLPAPER_TARGET_DIR="${CONFIG_TARGET_DIR}/hypr/wallpaper" # Target dir for wallpaper

if [ -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE}" ]; then
    echo "--- Forcefully copying Wallpaper ---"
    mkdir -p "${HYPR_WALLPAPER_TARGET_DIR}"
    cp -f "${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE}" "${HYPR_WALLPAPER_TARGET_DIR}/"
    echo "Wallpaper copied to ${HYPR_WALLPAPER_TARGET_DIR}/"
    echo "-------------------------------------------"
else
    echo "WARNING: Wallpaper source '${DOTFILES_SOURCE_DIR}/${WALLPAPER_SOURCE_FILE}' not found."
fi

# Example: A specific script
# This assumes your 'hypr' component copy already created ~/.config/hypr/scripts
HYPRPAPER_SCRIPT_SOURCE_PATH="scripts/config/hyprpaper.sh" # Relative to DOTFILES_SOURCE_DIR
HYPRPAPER_SCRIPT_TARGET_PATH="${CONFIG_TARGET_DIR}/hypr/scripts/hyprpaper.sh"

if [ -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH}" ]; then
    echo "--- Forcefully copying Hyprpaper script ---"
    mkdir -p "$(dirname "${HYPRPAPER_SCRIPT_TARGET_PATH}")"
    cp -f "${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH}" "${HYPRPAPER_SCRIPT_TARGET_PATH}"
    chmod +x "${HYPRPAPER_SCRIPT_TARGET_PATH}"
    echo "Hyprpaper script copied and made executable."
    echo "-------------------------------------------"
else
    echo "WARNING: Hyprpaper script source '${DOTFILES_SOURCE_DIR}/${HYPRPAPER_SCRIPT_SOURCE_PATH}' not found."
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
