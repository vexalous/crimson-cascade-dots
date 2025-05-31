#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/env.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Environment"

cat << EOF > "$TARGET_FILE"
env = XCURSOR_SIZE,${TARGET_CURSOR_SIZE:-24}
env = HYPRCURSOR_THEME,${TARGET_CURSOR_THEME:-Bibata-Modern-Classic}
env = HYPRCURSOR_SIZE,${TARGET_CURSOR_SIZE:-24}
env = XCURSOR_THEME,${TARGET_CURSOR_THEME:-Bibata-Modern-Classic}
env = QT_QPA_PLATFORM,wayland

# The following variable is expected to be set by the setup.sh script
# (typically in \$HOME/.config/hypr/conf/env.conf) to point to the
# directory where hyprland scripts are installed by setup.sh.
# For the repository version of this file (hypr/conf/env.conf),
# this comment serves as a placeholder and documentation.
# The setup.sh script will add/uncomment the actual 'env = HYPR_SCRIPTS_DIR,...' line.
# Example of what setup.sh might add:
# env = HYPR_SCRIPTS_DIR,\\$HOME/.config/hypr/scripts
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Environment"
