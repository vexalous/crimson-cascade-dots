#!/usr/bin/env bash
# This script defines common color variables that can be sourced by other scripts.
set -euo pipefail

# Color definitions
CRIMSON="#DC143C"    # A deep red color
LIGHT_GRAY="#cccccc" # A light gray color
NEAR_BLACK="#0a0a0a" # A very dark gray, almost black

# It's good practice for sourced files to end with a success code,
# though not strictly necessary for variable definitions.
# This prevents the sourcing script from exiting if 'set -e' is active and this was the last command.
exit 0
