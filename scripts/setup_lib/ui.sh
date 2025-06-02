#!/usr/bin/env bash
# This script provides simple UI helper functions for the main setup script,
# such as printing standardized headers or messages.
set -euo pipefail

# Prints a standardized header message for the setup script.
print_header() {
    echo "--------------------------------------------------------------------"
    echo " Crimson Cascade Dotfiles Setup"
    echo "--------------------------------------------------------------------"
}
