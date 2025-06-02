#!/usr/bin/env bash
# This script provides functions to verify essential command-line tool dependencies
# required by the main setup script or other utility scripts.
set -euo pipefail

# Checks for the presence of essential command-line tools in the system's PATH.
# Exits the script if any critical dependencies are missing.
verify_core_dependencies() {
    # List of essential commands that must be available.
    # This list should be updated if new tools become critical.
    local essential_commands=("git" "brightnessctl" "notify-send")
    local missing_commands=()    # Array to store names of missing commands
    local command_found_status=0 # Flag to track if all commands are found (0 = all found, 1 = some missing)

    echo "Verifying core command-line tool dependencies..." >&2

    for cmd in "${essential_commands[@]}"; do
        # 'command -v "$cmd"' checks if the command exists in PATH.
        # '&>/dev/null' suppresses any output (stdout and stderr) from this check.
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
            command_found_status=1 # Mark that at least one command is missing
        fi
    done

    if [ "$command_found_status" -ne 0 ]; then
        echo "ERROR: The following required commands are not found in your PATH:" >&2
        for mc in "${missing_commands[@]}"; do
            echo "  - $mc" >&2
        done
        echo "Please install them and re-run the script." >&2
        exit 1
    else
        echo "All core command-line tool dependencies verified." >&2
    fi
    echo "" >&2
}
