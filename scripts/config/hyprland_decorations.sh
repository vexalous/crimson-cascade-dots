#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="$HYPR_CONF_TARGET_DIR/decorations.conf"

echo "Generating $TARGET_FILE..."
mkdir -p "$(dirname "$TARGET_FILE")"

cat << EOF > "$TARGET_FILE"
decoration {
    rounding = 8
    blur {
        enabled = true; size = 6; passes = 3; new_optimizations = true;
        xray = true; noise = 0.015; contrast = 1.0; brightness = 0.95;
    }
}
EOF

echo "$TARGET_FILE generated."
