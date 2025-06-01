#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

DEFAULT_WALLPAPER_NAME="crimson_black_wallpaper.png"
HYPRPAPER_CONF_FILE="$CONFIG_TARGET_DIR/hypr/hyprpaper.conf"
USER_WALLPAPER_CONFIG_FILE="$CONFIG_TARGET_DIR/hypr/user_wallpaper.conf"
DEFAULT_WALLPAPER_TARGET_DIR="$CONFIG_TARGET_DIR/hypr/wallpaper"

# Ensure the directory for the default wallpaper image exists.
# This is where the default wallpaper image is expected to be copied by other scripts.
mkdir -p "$DEFAULT_WALLPAPER_TARGET_DIR"

# Path to be written into hyprpaper.conf for the default wallpaper.
# Note the use of \$HOME, which hyprpaper will expand.
DEFAULT_WALLPAPER_HYPRPAPER_PATH="\$HOME/.config/hypr/wallpaper/$DEFAULT_WALLPAPER_NAME"

# Initialize with the default wallpaper path. This will be updated if a user config is found and valid.
CHOSEN_WALLPAPER_HYPRPAPER_PATH="$DEFAULT_WALLPAPER_HYPRPAPER_PATH"

# User wallpaper configuration
# Users can create a file at $USER_WALLPAPER_CONFIG_FILE (e.g., ~/.config/hypr/user_wallpaper.conf)
# to specify a custom wallpaper. The file should contain a line like:
#   wallpaper_path = /path/to/your/image.png
# or using tilde for home directory:
#   wallpaper_path = ~/Pictures/your_image.jpg
# If this file is not found, or the path specified is invalid, the script
# will fall back to using the default wallpaper.

if [[ -f "$USER_WALLPAPER_CONFIG_FILE" ]]; then
    # Attempt to read the wallpaper_path from the user's config file.
    # grep gets the line (or nothing if not found), sed extracts the value after '=', and xargs trims whitespace.
    # The '|| true' after grep ensures the script doesn't exit if wallpaper_path is not found (due to set -e).
    USER_SPECIFIED_PATH_RAW=$(
        grep -E '^[[:space:]]*wallpaper_path[[:space:]]*=' "$USER_WALLPAPER_CONFIG_FILE" || true \
        | sed -E 's/^[[:space:]]*wallpaper_path[[:space:]]*=[[:space:]]*//' \
        | xargs
    )

    if [[ -n "$USER_SPECIFIED_PATH_RAW" ]]; then
        # Expand tilde (e.g., convert ~/Pictures to /home/user/Pictures) safely.
        # Using unquoted variables with glob patterns on the right side of == in [[ ... ]]
        if [[ $USER_SPECIFIED_PATH_RAW == ~/* ]]; then
            USER_SPECIFIED_PATH_EXPANDED="$HOME/${USER_SPECIFIED_PATH_RAW#"~/"}"
        elif [[ $USER_SPECIFIED_PATH_RAW == ~ ]]; then
            USER_SPECIFIED_PATH_EXPANDED="$HOME"
        else
            USER_SPECIFIED_PATH_EXPANDED="$USER_SPECIFIED_PATH_RAW"
        fi

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
prepare_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"
cat << EOF > "$HYPRPAPER_CONF_FILE"
preload = $CHOSEN_WALLPAPER_HYPRPAPER_PATH
wallpaper = ,$CHOSEN_WALLPAPER_HYPRPAPER_PATH
ipc = off
EOF
finish_target_file_write "$HYPRPAPER_CONF_FILE" "Hyprpaper"

echo "INFO: hyprpaper.conf generated at $HYPRPAPER_CONF_FILE with wallpaper $CHOSEN_WALLPAPER_HYPRPAPER_PATH"
