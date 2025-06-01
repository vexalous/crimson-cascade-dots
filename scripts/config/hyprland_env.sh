#!/usr/bin/env bash
# This script generates the Hyprland environment configuration file (env.conf).
# This file is sourced by Hyprland to set environment variables for the session.
# It uses helper functions from 'common.sh'.
set -euo pipefail

# Source common library functions for configuration file management.
source "$(dirname "$0")/../config_lib/common.sh"

# Define the target path for the Hyprland environment configuration file.
# HYPR_CONF_TARGET_DIR is expected to be an environment variable,
# likely pointing to something like ~/.config/hypr/conf/.
TARGET_FILE="$HYPR_CONF_TARGET_DIR/env.conf"

# Prepare the target file for writing (e.g., backup, create directories).
prepare_target_file_write "$TARGET_FILE" "Hyprland Environment"

# Use a 'here document' to write the environment variable settings.
# Variables like ${TARGET_CURSOR_SIZE:-24} use shell parameter expansion:
# if TARGET_CURSOR_SIZE is set and not empty, use its value; otherwise, use 24.
cat << EOF > "$TARGET_FILE"
# Environment variables for Hyprland

# Cursor theme and size settings
# XCURSOR_SIZE and XCURSOR_THEME are for XWayland applications.
# HYPRCURSOR_THEME and HYPRCURSOR_SIZE are for Hyprland's native cursor.
env = XCURSOR_SIZE,${TARGET_CURSOR_SIZE:-24}
env = HYPRCURSOR_THEME,${TARGET_CURSOR_THEME:-Bibata-Modern-Classic}
env = HYPRCURSOR_SIZE,${TARGET_CURSOR_SIZE:-24}
env = XCURSOR_THEME,${TARGET_CURSOR_THEME:-Bibata-Modern-Classic}

# Instruct Qt applications to use the Wayland platform adapter.
env = QT_QPA_PLATFORM,wayland

# --- HYPR_SCRIPTS_DIR Placeholder ---
# The main setup.sh script is responsible for populating the HYPR_SCRIPTS_DIR variable.
# This variable should point to the directory where custom Hyprland helper scripts
# (e.g., for brightness, volume, power menu) are located after installation.
#
# The comment block below is a placeholder in this template. The actual setup script
# will replace or append the correct 'env = HYPR_SCRIPTS_DIR,...' line to the
# user's deployed env.conf file.

# The following variable is expected to be set by the setup.sh script
# (typically in \$HOME/.config/hypr/conf/env.conf) to point to the
# directory where hyprland scripts are installed by setup.sh.
# For the repository version of this file (hypr/conf/env.conf),
# this comment serves as a placeholder and documentation.
# The setup.sh script will add/uncomment the actual 'env = HYPR_SCRIPTS_DIR,...' line.
# Example of what setup.sh might add:
# env = HYPR_SCRIPTS_DIR,\$HOME/.config/hypr/scripts
EOF

# Finalize the write operation for the target file.
finish_target_file_write "$TARGET_FILE" "Hyprland Environment"
