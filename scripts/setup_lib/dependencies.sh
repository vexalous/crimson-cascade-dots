#!/usr/bin/env bash
set -euo pipefail

verify_core_dependencies() {
    local missing_commands=()
    local command_found_status=0

    echo "Verifying core command-line tool dependencies..." >&2

    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
            command_found_status=1
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
