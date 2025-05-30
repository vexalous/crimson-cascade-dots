#!/usr/bin/env bash
set -euo pipefail

prompt_dependencies() {
    echo "Ensure core dependencies are installed."
    read -p "Are core dependencies installed? (y/N): " deps_installed_reply
    deps_installed_reply=$(echo "$deps_installed_reply" | tr '[:upper:]' '[:lower:]')
    if [[ "$deps_installed_reply" != "y" && "$deps_installed_reply" != "yes" ]]; then
        echo "Please install dependencies and re-run."
        exit 1
    fi
    echo ""
}
