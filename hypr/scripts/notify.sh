#!/usr/bin/env bash
set -euo pipefail

# Source the shared color definitions
# shellcheck source=./colors.sh
source "$(dirname "$0")/colors.sh"

# Default values
DEFAULT_APP_NAME="System Notification"
DEFAULT_ICON="dialog-information"
DEFAULT_TITLE="Notification"
DEFAULT_TEXT=""
DEFAULT_PROGRESS_VALUE=-1

usage() {
    echo "Usage: $0 -t <title> -m <message> [-a <app_name>] [-i <icon_path>] [-p <progress_value>]"
    echo "  -t : Title of the notification (required)"
    echo "  -m : Message body of the notification (required)"
    echo "  -a : Application name (optional, default: $DEFAULT_APP_NAME)"
    echo "  -i : Icon path or name (optional, default: $DEFAULT_ICON)"
    echo "  -p : Progress value (0-100) to display a progress bar (optional)"
    exit 1
}

TITLE=""
MESSAGE=""
APP_NAME="$DEFAULT_APP_NAME"
ICON_PATH="$DEFAULT_ICON"
PROGRESS_VALUE="$DEFAULT_PROGRESS_VALUE"

# Parse arguments
while getopts ":t:m:a:i:p:h" opt; do
    case $opt in
        t) TITLE="$OPTARG" ;;
        m) MESSAGE="$OPTARG" ;;
        a) APP_NAME="$OPTARG" ;;
        i) ICON_PATH="$OPTARG" ;;
        p) PROGRESS_VALUE="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [ -z "$TITLE" ] || [ -z "$MESSAGE" ]; then
    echo "Error: Title and message are required." >&2
    usage
fi

# Construct notify-send command
declare -a notify_args=()

notify_args+=("-u" "low")
notify_args+=("-a" "$APP_NAME")
notify_args+=("-i" "$ICON_PATH")
notify_args+=("-h" "string:fgcolor:$LIGHT_GRAY")
notify_args+=("-h" "string:bgcolor:$NEAR_BLACK")
notify_args+=("-h" "string:hlcolor:$CRIMSON")
notify_args+=("-h" "string:x-canonical-private-synchronous:hypr_notification")

if [[ "$PROGRESS_VALUE" -ge 0 && "$PROGRESS_VALUE" -le 100 ]]; then
    notify_args+=("-h" "int:value:$PROGRESS_VALUE")
fi

notify_args+=("$TITLE")
notify_args+=("$MESSAGE")

notify-send "${notify_args[@]}"

exit 0
