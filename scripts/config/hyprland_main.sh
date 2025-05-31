#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

HYPRLAND_CONF_MAIN_TARGET="$CONFIG_TARGET_DIR/hypr/hyprland.conf"
prepare_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"

cat << EOF > "$HYPRLAND_CONF_MAIN_TARGET"
monitor=,preferred,auto,1
source = conf/env.conf
source = conf/execs.conf
source = conf/general.conf
source = conf/input_gestures.conf
source = conf/layouts.conf
source = conf/misc.conf
source = conf/decorations.conf
source = conf/animations.conf
source = conf/keybinds.conf
source = conf/windowrules.conf
EOF
finish_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"
