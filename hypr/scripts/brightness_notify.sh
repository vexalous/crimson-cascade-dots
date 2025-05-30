#!/usr/bin/env bash
set -euo pipefail
CRIMSON="#DC143C"
LIGHT_GRAY="#cccccc"
NEAR_BLACK="#0a0a0a"
APP_NAME="Brightness"
ICON_LOW="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-low.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-medium.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/48x48/status/notification-display-brightness-high.svg"

B=$(brightnessctl g)
M=$(brightnessctl m)
P=$((B*100/M))

if [ $P -lt 34 ];then 
    I=$ICON_LOW
elif [ $P -lt 67 ];then 
    I=$ICON_MEDIUM
else 
    I=$ICON_HIGH
fi
notify-send -h string:x-canonical-private-synchronous:bright_notif -h int:value:$P -u low -i "$I" -a "$APP_NAME" "Brightness ${P}%" --hint=string:fgcolor:$LIGHT_GRAY,string:bgcolor:$NEAR_BLACK,string:hlcolor:$CRIMSON
