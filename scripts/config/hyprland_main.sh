#!/usr/bin/env bash
# This script generates the main Hyprland configuration file (hyprland.conf).
# This file acts as the entry point for Hyprland's configuration, primarily by
# sourcing other more specific .conf files from the 'conf/' subdirectory.
# It uses helper functions from 'common.sh'.
set -euo pipefail

# Source common library functions for configuration file management.
source "$(dirname "$0")/../config_lib/common.sh"

# Define the target path for the main Hyprland configuration file.
# CONFIG_TARGET_DIR is an environment variable, likely ~/.config.
# So, this usually targets ~/.config/hypr/hyprland.conf.
HYPRLAND_CONF_MAIN_TARGET="$CONFIG_TARGET_DIR/hypr/hyprland.conf"

# Prepare the target file for writing.
prepare_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"

# Use a 'here document' to write the content of hyprland.conf.
# This file sets up the primary monitor and sources all other configuration modules.
cat << EOF > "$HYPRLAND_CONF_MAIN_TARGET"
# Main Hyprland configuration file
# It sets basic monitor settings and sources other configuration files
# from the 'conf/' subdirectory (relative to this file's location).

# Autoconfigure the primary monitor: use preferred resolution, auto position, scale 1.
monitor=,preferred,auto,1

# Source individual configuration files.
# This modular approach keeps the configuration organized.
source = conf/env.conf          # Environment variables
source = conf/execs.conf         # Startup applications and commands
source = conf/general.conf       # General Hyprland settings (gaps, borders, layout type)
source = conf/input_gestures.conf # Input devices (keyboard, mouse, touchpad) and gestures
source = conf/layouts.conf       # Layout-specific settings (e.g., for dwindle, master)
source = conf/misc.conf          # Miscellaneous settings
source = conf/decorations.conf   # Window decorations (shadows, rounding)
source = conf/animations.conf    # Animation settings
source = conf/keybinds.conf      # Key bindings
source = conf/windowrules.conf   # Rules for specific windows (floating, opacity, etc.)
EOF

# Finalize the write operation for the target file.
finish_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"
