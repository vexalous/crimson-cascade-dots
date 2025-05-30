#!/usr/bin/env bash
set -euo pipefail
TARGET_FILE="$ALACRITTY_TARGET_DIR/alacritty.toml"
prepare_target_file_write "$TARGET_FILE" "Alacritty"
cat << 'EOF' > "$TARGET_FILE"
[env]
TERM = "alacritty"
[window]
padding = { x = 10, y = 10 }
opacity = 0.94
[scrolling]
history = 10000
multiplier = 3
[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 11.0
[colors.primary]
background = "#0a0a0a"
foreground = "#cccccc"
[colors.cursor]
text = "#0a0a0a"
cursor = "#DC143C"
[colors.selection]
text = "#f0f0f0"
background = "#8B0000"
[colors.normal]
black =   "#1a1a1a"
red =     "#DC143C"
green =   "#a0102c"
yellow =  "#8B0000"
blue =    "#505050"
magenta = "#DC143C"
cyan =    "#a0102c"
white =   "#cccccc"
[colors.bright]
black =   "#3d3d3d"
red =     "#FF0000"
green =   "#DC143C"
yellow =  "#a0102c"
blue =    "#606060"
magenta = "#FF0000"
cyan =    "#DC143C"
white =   "#f0f0f0"
[bell]
animation = "EaseOutExpo"
duration = 100
color = "#DC143C"
[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"
[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"
EOF
finish_target_file_write "$TARGET_FILE" "Alacritty"
