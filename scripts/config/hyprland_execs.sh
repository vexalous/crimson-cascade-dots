#!/bin/bash

TARGET_FILE="$HYPR_CONF_TARGET_DIR/execs.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

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

echo "$TARGET_FILE generated."
