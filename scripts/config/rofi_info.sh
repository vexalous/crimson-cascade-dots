#!/usr/bin/env bash
# This script provides an informational message regarding Rofi theme customization.
# It does not generate any Rofi configuration files itself.
# The actual Rofi theme (e.g., for the power menu) is expected to be part of the
# static dotfiles (e.g., in hypr/rofi/powermenu_theme.rasi) and copied by the setup script.
set -euo pipefail

# Source common library functions (though not strictly used in this script,
# it's included for consistency with other scripts in this directory).
source "$(dirname "$0")/../config_lib/common.sh"

# This script primarily serves to output an informational message.
# The environment variables ROFI_TARGET_DIR and HYPR_CONF_TARGET_DIR
# are expected to be set by the calling script or environment to provide
# relevant paths in the output message.
echo "INFO: Rofi theming for elements like the power menu is typically handled by a .rasi theme file."
echo "      For this dotfiles setup, the power menu theme is usually located at 'hypr/rofi/powermenu_theme.rasi'"
echo "      and is copied during the main setup."
echo "      You can customize Rofi further. If a general Rofi config directory is used (e.g., via \$ROFI_TARGET_DIR like '$ROFI_TARGET_DIR'),"
echo "      check there. Keybindings invoking Rofi are in Hyprland's keybinds.conf (e.g., in '$HYPR_CONF_TARGET_DIR/keybinds.conf')."
