#!/usr/bin/env bash
# This script generates the Alacritty terminal emulator configuration file (alacritty.toml).
# It uses helper functions from 'common.sh' to prepare and finalize the write operation.
set -euo pipefail

# Source common library functions for configuration file management.
# The path is relative to this script's location.
source "$(dirname "$0")/../config_lib/common.sh"

# Define the target path for the Alacritty configuration file.
# ALACRITTY_TARGET_DIR is expected to be an environment variable,
# likely set by the main setup script or sourced from another config file.
TARGET_FILE="$ALACRITTY_TARGET_DIR/alacritty.toml"

# Prepare the target file for writing.
# This function (from common.sh) likely handles backup of existing file and creates parent directories.
# "Alacritty" is passed as the component name for logging/messaging.
prepare_target_file_write "$TARGET_FILE" "Alacritty"

# Use a 'here document' (cat << 'EOF' ... EOF) to write the Alacritty configuration.
# The 'EOF' delimiter is quoted to prevent variable expansion and command substitution within the here document,
# ensuring the content is written literally.
cat << 'EOF' > "$TARGET_FILE"
[env]
TERM = "alacritty" # Set the TERM environment variable within Alacritty

[window]
padding = { x = 10, y = 10 } # Window padding
opacity = 0.94              # Window opacity (requires a compositor that supports transparency)

[scrolling]
history = 10000 # Number of lines to keep in scrollback history
multiplier = 3  # Scrolling speed multiplier

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 11.0 # Font size

[colors.primary]
background = "#0a0a0a" # Primary background color
foreground = "#cccccc" # Primary foreground (text) color

[colors.cursor]
text = "#0a0a0a"       # Text color under the cursor
cursor = "#DC143C"     # Cursor color

[colors.selection]
text = "#f0f0f0"       # Text color of selected text
background = "#8B0000" # Background color of selected text

[colors.normal] # Normal ANSI colors
black =   "#1a1a1a"
red =     "#DC143C"
green =   "#a0102c"
yellow =  "#8B0000"
blue =    "#505050"
magenta = "#DC143C"
cyan =    "#a0102c"
white =   "#cccccc"

[colors.bright] # Bright ANSI colors
black =   "#3d3d3d"
red =     "#FF0000"
green =   "#DC143C"
yellow =  "#a0102c"
blue =    "#606060"
magenta = "#FF0000"
cyan =    "#DC143C"
white =   "#f0f0f0"

[bell]
animation = "EaseOutExpo" # Bell animation style
duration = 100            # Bell animation duration in milliseconds
color = "#DC143C"         # Bell color (often a flash)

[[keyboard.bindings]] # Custom key bindings
key = "V"
mods = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"
EOF

# Finalize the write operation for the target file.
# This function (from common.sh) might handle permissions or logging.
finish_target_file_write "$TARGET_FILE" "Alacritty"
