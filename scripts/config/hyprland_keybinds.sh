#!/bin/bash

TARGET_FILE="$HYPR_CONF_TARGET_DIR/keybinds.conf"

echo "Generating $TARGET_FILE with Sway/i3 style keybinds..."
mkdir -p "$(dirname "$TARGET_FILE")"

cat << 'EOF' > "$TARGET_FILE"
$mainMod = SUPER

bind = $mainMod, Return, exec, alacritty
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, W, exec, firefox

bind = $mainMod SHIFT, Q, killactive,
bind = $mainMod SHIFT, C, exec, hyprctl reload
bind = $mainMod SHIFT, E, exit,

bind = $mainMod, H, movefocus, l
bind = $mainMod, J, movefocus, d
bind = $mainMod, K, movefocus, u
bind = $mainMod, L, movefocus, r
bind = $mainMod, Left, movefocus, l
bind = $mainMod, Down, movefocus, d
bind = $mainMod, Up, movefocus, u
bind = $mainMod, Right, movefocus, r

bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, J, movewindow, d
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, Left, movewindow, l
bind = $mainMod SHIFT, Down, movewindow, d
bind = $mainMod SHIFT, Up, movewindow, u
bind = $mainMod SHIFT, Right, movewindow, r

bind = $mainMod, F, fullscreen, 0
bind = $mainMod SHIFT, Space, togglefloating,

bind = $mainMod, S, layoutmsg, togglesplit # Dwindle: toggle horiz/vert split for next container
# For master layout, you might want:
# bind = $mainMod, S, layoutmsg, swapwithmaster
# bind = $mainMod, S, layoutmsg, orientationnext # if master layout supports it

binde = $mainMod, R, submap, resize
submap = resize
binde =, H, resizeactive, -20 0
binde =, L, resizeactive, 20 0
binde =, K, resizeactive, 0 -20
binde =, J, resizeactive, 0 20
binde =, Left, resizeactive, -20 0
binde =, Right, resizeactive, 20 0
binde =, Up, resizeactive, 0 -20
binde =, Down, resizeactive, 0 20
bind =, Escape, submap, reset
submap = reset

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1
bind = $mainMod, Tab, workspace, previous

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

bind = $mainMod, GRAVE, togglespecialworkspace, scratchpad

binde=, XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5% && ~/.config/hypr/scripts/volume_notify.sh
binde=, XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5% && ~/.config/hypr/scripts/volume_notify.sh
bindl=, XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle && ~/.config/hypr/scripts/volume_notify.sh
bindl=, XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle && ~/.config/hypr/scripts/volume_notify.sh MUTE
binde=, XF86MonBrightnessUp, exec, brightnessctl set +5% && ~/.config/hypr/scripts/brightness_notify.sh
binde=, XF86MonBrightnessDown, exec, brightnessctl set 5%- && ~/.config/hypr/scripts/brightness_notify.sh
bind = , Print, exec, grim -g "$(slurp -d -b '#0a0a0acc' -c '#DC143Cff' -s '#00000055' -w 2)" - | swappy -f -
bind = $mainMod, Print, exec, grim -g "$(hyprctl -j activewindow | jq -r '.at[0],.at[1],.size[0],.size[1] | \"\(.[0]),\(.[1]) \(.[2])x\(.[3])\"')" - | swappy -f -
bind = SHIFT, Print, exec, grim - | swappy -f -
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp -d -b '#0a0a0acc' -c '#DC143Cff' -s '#00000055' -w 2)" - | wl-copy && makoctl notify "Screenshot Copied" "Selected area copied to clipboard."
bind = $mainMod, L, exec, hyprlock
EOF

echo "$TARGET_FILE generated with Sway/i3 style keybinds."
