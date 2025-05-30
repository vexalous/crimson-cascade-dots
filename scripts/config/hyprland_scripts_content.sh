#!/usr/bin/env bash
set -euo pipefail
echo "Generating Hyprland helper scripts in $HYPR_SCRIPTS_TARGET_DIR..."
mkdir -p "$HYPR_SCRIPTS_TARGET_DIR"
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/idle_config.sh"
#!/bin/bash
hypridle \
    timeout 300 'hyprlock' \
    timeout 330 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    timeout 600 'systemctl suspend' \
    before-sleep 'hyprlock && sleep 1' &
EOF
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/volume_notify.sh"
#!/bin/bash
CRIMSON="#DC143C"; LIGHT_GRAY="#cccccc"; NEAR_BLACK="#0a0a0a"; ICON_MUTED="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-muted.svg"; ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-low.svg";ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-medium.svg";ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/panel/audio-volume-high.svg";ICON_MIC_MUTED="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone-muted.svg";ICON_MIC="/usr/share/icons/Papirus-Dark/48x48/devices/audio-input-microphone.svg"
get_v(){ pactl get-sink-volume @DEFAULT_SINK@|grep -Po '[0-9]+(?=%)'|head -n 1;};is_m(){ pactl get-sink-mute @DEFAULT_SINK@|grep -q yes;};is_mic_m(){ pactl get-source-mute @DEFAULT_SOURCE@|grep -q yes;}
if [[ "$1" == MUTE ]];then N="Microphone";if is_mic_m;then I=$ICON_MIC_MUTED;T="Mic Muted";P=0;else I=$ICON_MIC;T="Mic On";P=100;fi;else N="Volume";V=$(get_v);if is_m||[ "$V" -eq 0 ];then I=$ICON_MUTED;T="Muted";P=0;elif [ "$V" -lt 34 ];then I=$ICON_LOW;T="${V}%";P=$V;elif [ "$V" -lt 67 ];then I=$ICON_MEDIUM;T="${V}%";P=$V;else I=$ICON_HIGH;T="${V}%";P=$V;fi;fi
notify-send -h string:x-canonical-private-synchronous:vol_notif -h int:value:$P -u low -i "$I" -a "$N" "$T" --hint=string:fgcolor:$LIGHT_GRAY,string:bgcolor:$NEAR_BLACK,string:hlcolor:$CRIMSON
EOF
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/brightness_notify.sh"
#!/bin/bash
CRIMSON="#DC143C";LIGHT_GRAY="#cccccc";NEAR_BLACK="#0a0a0a";APP_NAME="Brightness";ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-low.svg";ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-medium.svg";ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-high.svg"
B=$(brightnessctl g);M=$(brightnessctl m);P=$((B*100/M));if [ $P -lt 34 ];then I=$ICON_LOW;elif [ $P -lt 67 ];then I=$ICON_MEDIUM;else I=$ICON_HIGH;fi
notify-send -h string:x-canonical-private-synchronous:bright_notif -h int:value:$P -u low -i "$I" -a "$APP_NAME" "Brightness ${P}%" --hint=string:fgcolor:$LIGHT_GRAY,string:bgcolor:$NEAR_BLACK,string:hlcolor:$CRIMSON
EOF
cat << 'EOF' > "$HYPR_SCRIPTS_TARGET_DIR/rofi_powermenu.sh"
#!/bin/bash
shutdown="Shutdown"; reboot="Reboot"; lock="Lock Screen"; logout="Logout"
selected_option=$(echo -e "$lock\n$logout\n$reboot\n$shutdown" | rofi -dmenu -p "Power" -i -mesg "System Actions")
case "$selected_option" in "$shutdown") systemctl poweroff ;; "$reboot") systemctl reboot ;; "$lock") hyprlock ;; "$logout") loginctl terminate-session self ;; esac
EOF
chmod +x "$HYPR_SCRIPTS_TARGET_DIR"/*.sh
echo "Hyprland helper scripts generated."
