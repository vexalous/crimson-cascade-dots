#!/usr/bin/env bash
# This script is a wrapper for notify-send to display customized desktop notifications.
# It allows setting title, message, app name, icon, and progress value via command-line arguments.
set -euo pipefail

# Source the shared color definitions
# shellcheck source=./colors.sh
source "$(dirname "$0")/colors.sh"

# Default values for notification parameters
DEFAULT_APP_NAME="System Notification"
DEFAULT_ICON="dialog-information" # A standard system icon
DEFAULT_TITLE="Notification"
DEFAULT_TEXT="" # Message body, should be provided by the user
DEFAULT_PROGRESS_VALUE=-1 # Use -1 or an empty string to indicate no progress bar

# Displays usage information and exits.
usage() {
    echo "Usage: $0 -t <title> -m <message> [-a <app_name>] [-i <icon_path>] [-p <progress_value>]"
    echo "  -t : Title of the notification (required)"
    echo "  -m : Message body of the notification (required)"
    echo "  -a : Application name (optional, default: $DEFAULT_APP_NAME)"
    echo "  -i : Icon path or name (optional, default: $DEFAULT_ICON)"
    echo "  -p : Progress value (0-100) to display a progress bar (optional)"
    exit 1
}

# Initialize variables with default values
TITLE=""
MESSAGE=""
APP_NAME="$DEFAULT_APP_NAME"
ICON_PATH="$DEFAULT_ICON"
PROGRESS_VALUE="$DEFAULT_PROGRESS_VALUE"

# Parse command-line options
while getopts ":t:m:a:i:p:h" opt; do
    case $opt in
        t) TITLE="$OPTARG" ;;          # Set Title
        m) MESSAGE="$OPTARG" ;;        # Set Message
        a) APP_NAME="$OPTARG" ;;       # Set App Name
        i) ICON_PATH="$OPTARG" ;;      # Set Icon Path
        p) PROGRESS_VALUE="$OPTARG" ;; # Set Progress Value
        h) usage ;;                    # Display help/usage
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;; # Handle invalid option
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;; # Handle missing argument
    esac
done

# Check if required arguments (title and message) are provided
if [ -z "$TITLE" ] || [ -z "$MESSAGE" ]; then
    echo "Error: Title and message are required." >&2
    usage
fi

# Construct notify-send command arguments in an array
declare -a notify_args=()

notify_args+=("-u" "low") # Set urgency to low
notify_args+=("-a" "$APP_NAME") # Set application name
notify_args+=("-i" "$ICON_PATH") # Set icon

# Set notification hints for styling (colors) and behavior
# These hints might be specific to certain notification daemons (e.g., Dunst)
notify_args+=("-h" "string:fgcolor:$LIGHT_GRAY")  # Foreground (text) color
notify_args+=("-h" "string:bgcolor:$NEAR_BLACK") # Background color
notify_args+=("-h" "string:hlcolor:$CRIMSON")    # Highlight color (e.g., for progress bar)

# This hint allows the notification to be replaced by its ID, preventing duplicate notifications
# if the script is called multiple times rapidly with the same purpose.
notify_args+=("-h" "string:x-canonical-private-synchronous:generic_notif")

# Add progress bar hint if PROGRESS_VALUE is within the valid range (0-100)
if [[ "$PROGRESS_VALUE" -ge 0 && "$PROGRESS_VALUE" -le 100 ]]; then
    notify_args+=("-h" "int:value:$PROGRESS_VALUE") # Pass progress value as an integer hint
fi

# Add title and message body as positional arguments
notify_args+=("$TITLE")
notify_args+=("$MESSAGE")

# Execute notify-send with all constructed arguments
notify-send "${notify_args[@]}"

# Exit successfully
exit 0
