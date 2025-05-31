#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$WAYBAR_TARGET_DIR/config"
WAYBAR_H=$WAYBAR_EXPECTED_HEIGHT
SCRIPTS_P="$HYPR_SCRIPTS_TARGET_DIR"
prepare_target_file_write "$TARGET_FILE" "Waybar Config"
cat << EOF > "$TARGET_FILE"
{"layer":"top","position":"top","height":${WAYBAR_H},"spacing":0,"modules-left":["hyprland/workspaces","hyprland/mode"],"modules-center":["hyprland/window"],"modules-right":["pulseaudio","network","cpu","memory","clock","tray","custom/power"],"hyprland/workspaces":{"all-outputs":false,"format":"{id}","format-icons":{"urgent":"","focused":"","default":"","empty":""},"persistent-workspaces":{},"on-click":"activate","sort-by-number":true},"hyprland/mode":{"format":"<span style=\"italic\">{}</span>","tooltip":false},"hyprland/window":{"format":"{}","max-length":50,"rewrite":{"(.*) - Ungoogled Chromium":"󰊯 \$1","(.*) - Mozilla Firefox":"🦊 \$1","(.*) — VSCodium":"󰨞 \$1","Alacritty":" Alacritty"}},"clock":{"format":" {:%I:%M %p}","format-alt":" {:%d %b %Y}","tooltip-format":"<big>{:%A, %d %B %Y}</big>\n<tt><small>{calendar}</small></tt>","on-click-middle":"mode"},"tray":{"icon-size":19,"spacing":10},"pulseaudio":{"format":"{icon} {volume}%","format-bluetooth":" {volume}%","format-muted":" Off","format-icons":{"default":["","",""]},"on-click":"pavucontrol","on-scroll-up":"pactl set-sink-volume @DEFAULT_SINK@ +2%","on-scroll-down":"pactl set-sink-volume @DEFAULT_SINK@ -2%","scroll-step":2},"network":{"format-wifi":" {essid}","format-ethernet":"󰈀 Eth","tooltip-format":"{ifname} ({ipaddr})  {gwaddr}\nSignal: {signalStrength}% Freq: {frequency}MHz\nDown: {bandwidthDownBits}, Up: {bandwidthUpBits}","format-linked":"󰈀 {ifname} (No IP)","format-disconnected":" Disconnected","on-click":"nm-connection-editor"},"cpu":{"format":" {usage:2}%","interval":2,"on-click":"alacritty -e btop"},"memory":{"format":" {used:0.1f}G","interval":5,"on-click":"alacritty -e htop"},"custom/power":{"format":"","tooltip":true,"tooltip-format":"Power Menu","on-click":"\$HYPR_SCRIPTS_DIR/rofi_powermenu.sh"}}
EOF
finish_target_file_write "$TARGET_FILE" "Waybar Config"
