#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$HYPR_CONF_TARGET_DIR/execs.conf"
prepare_target_file_write "$TARGET_FILE" "Hyprland Execs"

cat << EOF > "$TARGET_FILE"
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = waybar &
exec-once = hyprpaper &
exec-once = mako &
exec-once = $HYPR_SCRIPTS_TARGET_DIR/idle_config.sh &
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hyprctl setcursor $TARGET_CURSOR_THEME $TARGET_CURSOR_SIZE
EOF
finish_target_file_write "$TARGET_FILE" "Hyprland Execs"
