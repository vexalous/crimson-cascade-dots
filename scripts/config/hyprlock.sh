#!/bin/bash
echo "Generating $HYPRLOCK_TARGET_FILE..."
mkdir -p "$(dirname "$HYPRLOCK_TARGET_FILE")"
cat << EOF > "$HYPRLOCK_TARGET_FILE"
general {disable_loading_bar=true;hide_cursor=true;grace=0;no_fade_in=false;}
background {path=$WALLPAPER_FILE;color=$HL_NEAR_BLACK_RGBA;}
input-field {monitor=;size=400,55;outline_thickness=3;dots_size=0.28;dots_spacing=0.28;dots_center=true;dots_rounding=-1;inner_color=$HL_DARK_GRAY_INPUT_BG;outer_color=$HL_CRIMSON_SOLID;font_color=$HL_TEXT_FIELD_FONT_COLOR;fade_on_empty=true;fade_timeout=800;fade_alpha=0.15;placeholder_text=<i>ENTER PASSWORD</i>;placeholder_color=$HL_DIM_GRAY_PLACEHOLDER;hide_input=false;rounding=10;check_color=$HL_CRIMSON_SOLID;fail_color=$HL_DARK_RED_FAIL;fail_text=<b><span foreground="$HL_OFF_WHITE_TEXT" background="$HL_DARK_RED_FAIL" size="large"> ACCESS DENIED </span></b>;fail_transition=400;position=0,50;halign=center;valign=center;}
label {monitor=;text=cmd[update:1000] echo \$(date +"%H:%M");color=$HL_OFF_WHITE_TEXT;font_size=90;font_family="JetBrainsMono Nerd Font ExtraBold";position=0,-150;halign=center;valign=center;shadow_passes=2;shadow_color=rgba(0,0,0,0.4);shadow_size=3;shadow_boost=1.1;}
label {monitor=;text=cmd[update:3600000] echo \$(date +"%m/%d/%y");color=$HL_LIGHT_GRAY_TEXT;font_size=24;font_family="JetBrainsMono Nerd Font";position=0,-70;halign=center;valign=center;shadow_passes=1;shadow_color=rgba(0,0,0,0.3);shadow_size=2;}
EOF
echo "$HYPRLOCK_TARGET_FILE generated."
