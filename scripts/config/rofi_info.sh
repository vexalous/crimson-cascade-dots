#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

echo "INFO: Rofi uses default theme. Customize via $ROFI_TARGET_DIR or $HYPR_CONF_TARGET_DIR/keybinds.conf."
