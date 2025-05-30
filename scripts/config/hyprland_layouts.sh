#!/bin/bash

TARGET_FILE="$HYPR_CONF_TARGET_DIR/layouts.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

cat << EOF > "$TARGET_FILE"
dwindle {
    preserve_split = true
}

master {
}
EOF

echo "$TARGET_FILE generated."
