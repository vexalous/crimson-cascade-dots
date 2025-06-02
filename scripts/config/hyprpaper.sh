#!/usr/bin/env bash
# This script generates the hyprpaper.conf file.
# It prioritizes a user-defined wallpaper specified in 'user_wallpaper.conf'.
# If not found or invalid, it falls back to a default wallpaper.
# It uses helper functions from 'common.sh'.
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh" # For prepare_target_file_write, finish_target_file_write

# --- Configuration Variables ---
DEFAULT_WALLPAPER_NAME="crimson_black_wallpaper.png" # Default wallpaper filename

# Target path for the generated hyprpaper.conf. $CONFIG_TARGET_DIR is expected to be an env var (e.g., $HOME/.config).
HYPRPAPER_CONF_FILE="$CONFIG_TARGET_DIR/hypr/hyprpaper.conf"
# Path to the user's custom wallpaper configuration file.
USER_WALLPAPER_CONFIG_FILE="$CONFIG_TARGET_DIR/hypr/user_wallpaper.conf"
# Directory where the default wallpaper image is expected to be located.
DEFAULT_WALLPAPER_TARGET_DIR="$CONFIG_TARGET_DIR/hypr/wallpaper"


# --- Initialization ---
# Ensure the target directory for the default wallpaper image exists.
# This script assumes another process (e.g., main setup.sh) copies the actual image here.
mkdir -p "$DEFAULT_WALLPAPER_TARGET_DIR"

# Define the path for the default wallpaper as it will be written in hyprpaper.conf.
# '\$HOME' is a literal string; hyprpaper expands it at runtime.
DEFAULT_WALLPAPER_HYPRPAPER_PATH="\$HOME/.config/hypr/wallpaper/$DEFAULT_WALLPAPER_NAME"

# Initialize the chosen wallpaper path with the default. This may be overridden by user config.
CHOSEN_WALLPAPER_HYPRPAPER_PATH="$DEFAULT_WALLPAPER_HYPRPAPER_PATH"

# User wallpaper configuration
# Users can create a file at $USER_WALLPAPER_CONFIG_FILE (e.g., ~/.config/hypr/user_wallpaper.conf)
# to specify a custom wallpaper. The file should contain a line like:
#   wallpaper_path = /path/to/your/image.png
# or using tilde for home directory:
#   wallpaper_path = ~/Pictures/your_image.jpg
# If this file is not found, or the path specified is invalid, the script
# will fall back to using the default wallpaper.

# --- Process User Wallpaper Configuration ---
if [[ -f "$USER_WALLPAPER_CONFIG_FILE" ]]; then
    echo "INFO: Found user wallpaper config: $USER_WALLPAPER_CONFIG_FILE"
    # Attempt to read the 'wallpaper_path' from the user's config file.
    # Steps:
    # 1. grep: Find lines starting with "wallpaper_path" (case-insensitive for key if needed, but not done here).
    #    ' || true' prevents script exit if grep finds no match (due to 'set -e').
    # 2. sed: Remove "wallpaper_path =" part (and surrounding spaces) to extract the path value.
    # 3. xargs: Trim leading/trailing whitespace from the extracted path.
    USER_SPECIFIED_PATH_RAW=$(
        grep -E '^[[:space:]]*wallpaper_path[[:space:]]*=' "$USER_WALLPAPER_CONFIG_FILE" || true \
        | sed -E 's/^[[:space:]]*wallpaper_path[[:space:]]*=[[:space:]]*//' \
        | xargs
    )

    if [[ -n "$USER_SPECIFIED_PATH_RAW" ]]; then
        # Expand potential tilde (~) in the user-specified path.
        # This is a safe way to do it without using 'eval'.
        # Examples: ~/Pictures/wall.jpg -> /home/user/Pictures/wall.jpg
        #           ~                  -> /home/user
        if [[ $USER_SPECIFIED_PATH_RAW == "~/"* ]]; then # Path starts with "~/"
            USER_SPECIFIED_PATH_EXPANDED="$HOME/${USER_SPECIFIED_PATH_RAW#"~/"}"
        elif [[ $USER_SPECIFIED_PATH_RAW == "~" ]]; then # Path is just "~"
            USER_SPECIFIED_PATH_EXPANDED="$HOME"
        else # Path does not start with tilde, use as is.
            USER_SPECIFIED_PATH_EXPANDED="$USER_SPECIFIED_PATH_RAW"
        fi

        echo "INFO: User specified raw path: '$USER_SPECIFIED_PATH_RAW', expanded to: '$USER_SPECIFIED_PATH_EXPANDED'"
        if [[ -f "$USER_SPECIFIED_PATH_EXPANDED" ]]; then
            # If the user-specified path points to an existing file, use it.
            CHOSEN_WALLPAPER_HYPRPAPER_PATH="$USER_SPECIFIED_PATH_EXPANDED"
            echo "INFO: Using user-defined wallpaper: $CHOSEN_WALLPAPER_HYPRPAPER_PATH (from $USER_WALLPAPER_CONFIG_FILE)"
        else
            echo "WARN: User-defined wallpaper '$USER_SPECIFIED_PATH_EXPANDED' (raw: '$USER_SPECIFIED_PATH_RAW') not found. Falling back to default wallpaper."
        fi
    else
        echo "INFO: 'wallpaper_path' not found or is empty in $USER_WALLPAPER_CONFIG_FILE. Using default wallpaper."
    fi
else
    echo "INFO: User wallpaper config file '$USER_WALLPAPER_CONFIG_FILE' not found. Using default wallpaper."
fi

# If using the default wallpaper, provide an informational message.
# Also, check if the default wallpaper file actually exists, as a diagnostic aid.
if [[ "$CHOSEN_WALLPAPER_HYPRPAPER_PATH" == "$DEFAULT_WALLPAPER_HYPRPAPER_PATH" ]]; then
    DEFAULT_WALLPAPER_FS_PATH="$DEFAULT_WALLPAPER_TARGET_DIR/$DEFAULT_WALLPAPER_NAME" # Actual path on filesystem
    if [[ ! -f "$DEFAULT_WALLPAPER_FS_PATH" ]]; then
        echo "WARN: Default wallpaper '$DEFAULT_WALLPAPER_FS_PATH' not found! Please ensure it is correctly placed or run any necessary setup scripts."
    else
        echo "INFO: Using default wallpaper: $DEFAULT_WALLPAPER_FS_PATH"
    fi
# elif [[ -f "$CHOSEN_WALLPAPER_HYPRPAPER_PATH" ]]; then
    # This block is removed as the INFO message for user-defined wallpaper is already printed earlier.
    # No need for a redundant "Confirmed wallpaper selection" message.
fi

# Prepare and write the hyprpaper.conf file.
# This will use the CHOSEN_WALLPAPER_HYPRPAPER_PATH, which is either the user's valid custom path
# or the default path.
prepare_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper" # From common.sh
cat << EOF > "$HYPRPAPER_CONF_FILE"
# Hyprpaper Configuration File
# Generated by scripts/config/hyprpaper.sh

# Preload the wallpaper image into memory for faster display.
preload = $CHOSEN_WALLPAPER_HYPRPAPER_PATH

# Set the wallpaper.
# The leading comma means apply to all monitors/outputs.
# Example: wallpaper = DP-1,/path/to/image.png  (specific monitor)
#          wallpaper = ,/path/to/image.png     (all monitors)
wallpaper = ,$CHOSEN_WALLPAPER_HYPRPAPER_PATH

# Disable Inter-Process Communication (IPC) if not using hyprctl to change wallpapers dynamically.
ipc = off
EOF
finish_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper" # From common.sh

echo "INFO: hyprpaper.conf generated at $HYPRPAPER_CONF_FILE with wallpaper '$CHOSEN_WALLPAPER_HYPRPAPER_PATH'"
