#!/bin/bash

TARGET_FILE="$HYPR_CONF_TARGET_DIR/windowrules.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

cat << EOF > "$TARGET_FILE"
windowrulev2 = workspace special:scratchpad silent, title:^(AlacrittyScratchpad)$
windowrulev2 = float, title:^(AlacrittyScratchpad)$
windowrulev2 = size 60% 60%, title:^(AlacrittyScratchpad)$
windowrulev2 = center, title:^(AlacrittyScratchpad)$
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(blueman-manager)$
windowrulev2 = float,class:^(nm-connection-editor)$
windowrulev2 = float,class:^(org.kde.polkit-kde-authentication-agent-1)$
windowrulev2 = float,title:^(Open File)(.*)$
windowrulev2 = float,title:^(Select File)(.*)$
windowrulev2 = float,title:^(Choose wallpaper)(.*)$
windowrulev2 = float,title:^(Open Folder)(.*)$
windowrulev2 = float,title:^(Save As)(.*)$
windowrulev2 = float,title:^(File Upload)(.*)$
windowrulev2 = float,title:^(Volume Control)$
windowrulev2 = center,floating:1
windowrulev2 = opacity 0.94 0.88,class:^(Alacritty)$,title:^((?!AlacrittyScratchpad).)*$
layerrule = blur, mako
layerrule = ignorezero, mako
EOF

echo "$TARGET_FILE generated."
