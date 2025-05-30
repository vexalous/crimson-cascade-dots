#!/usr/bin/env bash
set -euo pipefail

HYPRLAND_CONF_MAIN_TARGET="$CONFIG_TARGET_DIR/hypr/hyprland.conf"

echo "Generating main Hyprland config: $HYPRLAND_CONF_MAIN_TARGET"
mkdir -p "$(dirname "$HYPRLAND_CONF_MAIN_TARGET")"

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

echo "Main Hyprland config ($HYPRLAND_CONF_MAIN_TARGET) generated."
