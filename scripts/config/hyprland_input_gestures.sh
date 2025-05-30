#!/bin/bash

TARGET_FILE="$HYPR_CONF_TARGET_DIR/input_gestures.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

cat << EOF > "$TARGET_FILE"
input {
    kb_layout = us
    kb_options = ctrl:nocaps
    follow_mouse = 1
    float_switch_override_focus = 0
    touchpad {
        disable_while_typing = true
    }
    accel_profile = flat
}

gestures {
}
EOF

echo "$TARGET_FILE generated."
