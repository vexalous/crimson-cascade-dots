#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

HYPRLAND_CONF_MAIN_TARGET="$CONFIG_TARGET_DIR/hypr/hyprland.conf"
prepare_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"

cat << EOF > "$HYPRLAND_CONF_MAIN_TARGET"
monitor=,preferred,auto,1
source = $HYPR_CONF_TARGET_DIR/env.conf
source = $HYPR_CONF_TARGET_DIR/execs.conf
source = $HYPR_CONF_TARGET_DIR/general.conf
source = $HYPR_CONF_TARGET_DIR/input_gestures.conf
source = $HYPR_CONF_TARGET_DIR/layouts.conf
source = $HYPR_CONF_TARGET_DIR/misc.conf
source = $HYPR_CONF_TARGET_DIR/decorations.conf
source = $HYPR_CONF_TARGET_DIR/animations.conf
source = $HYPR_CONF_TARGET_DIR/keybinds.conf
source = $HYPR_CONF_TARGET_DIR/windowrules.conf
EOF
finish_target_file_write "$HYPRLAND_CONF_MAIN_TARGET" "Hyprland Main"
