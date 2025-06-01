#!/usr/bin/env bash
# This script displays a power menu using Rofi, allowing the user to
# shutdown, reboot, lock the screen, or logout.
set -euo pipefail

# Define the strings for the menu options
SHUTDOWN_STR="Shutdown"
REBOOT_STR="Reboot"
LOCK_STR="Lock Screen"
LOGOUT_STR="Logout"

# Displays the Rofi power menu and returns the selected option.
display_menu() {
    local script_dir
    script_dir=$(dirname "$0") # Get the directory where the script is located

    # Pipe the options into Rofi
    # -dmenu: Run Rofi in dmenu mode (takes input from stdin)
    # -p "Power": Set the prompt text
    # -i: Case-insensitive matching
    # -mesg "System Actions": Display a message above the input bar
    # -theme: Use a custom Rofi theme for the power menu
    echo -e "$LOCK_STR\n$LOGOUT_STR\n$REBOOT_STR\n$SHUTDOWN_STR" | \
        rofi -dmenu -p "Power" -i -mesg "System Actions" -theme "$script_dir/../rofi/powermenu_theme.rasi"
}

# Executes the system action corresponding to the selected menu option.
# Args:
#   $1: The selected option string.
execute_action() {
    local option="$1"
    case "$option" in
        "$SHUTDOWN_STR")
            systemctl poweroff # Power off the system
            ;;
        "$REBOOT_STR")
            systemctl reboot   # Reboot the system
            ;;
        "$LOCK_STR")
            hyprlock           # Lock the screen using hyprlock
            ;;
        "$LOGOUT_STR")
            # Terminate the current user session.
            # 'self' refers to the session from which this command is run.
            loginctl terminate-session self
            ;;
    esac
}

# Main function: display the menu and execute the chosen action.
main() {
    local selected_option
    selected_option=$(display_menu) # Get the user's choice

    # If an option was selected (i.e., Rofi didn't exit without a choice)
    if [ -n "$selected_option" ]; then
        execute_action "$selected_option" # Perform the action
    fi
}

# Execute the main function
main
