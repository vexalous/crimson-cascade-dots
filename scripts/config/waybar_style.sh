#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

TARGET_FILE="$WAYBAR_TARGET_DIR/style.css"
prepare_target_file_write "$TARGET_FILE" "Waybar Style"
cat << 'EOF' > "$TARGET_FILE"
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free Solid", sans-serif;
    font-size: 14px;
    min-height: 0;
    padding: 0;
    margin: 0;
}

window#waybar {
    --bg-color: #0a0a0a;
    --fg-color: #cccccc;
    --accent-color: #DC143C;
    --accent-dark-color: #a0102c;
    --module-bg-color: #1a1a1a;
    --module-alt-bg-color: #141414;
    --module-border-color: #2c2c2c;
    --module-hover-bg-color: #3d3d3d;

    --text-hover-color: #f0f0f0;
    --text-bright-color: #ffffff;

    --workspace-button-fg-dimmed: #555555;
    --workspace-button-fg-persistent: #404040;
    --workspace-button-bg-visible: var(--module-border-color);
    --workspace-button-hover-border-color: var(--workspace-button-fg-dimmed);
    --workspace-button-visible-hover-bg-color: #4a4a4a;
    --workspace-button-visible-hover-border-color: #6c7086;

    --urgent-bg-color: #FFD700;
    --urgent-fg-color: #000000;
    --urgent-hover-bg-color: #ffec80;
    --urgent-hover-fg-color: var(--bg-color);

    --hyprland-window-text-color: #b4befe;
    --clock-text-color: #E6E6FA;
    --pulseaudio-text-color: #fab387;
    --pulseaudio-muted-bg-color: var(--module-hover-bg-color);
    --pulseaudio-muted-text-color: #6c7086;
    --network-text-color: #f9e2af;
    --network-disconnected-bg-color: #f38ba8;
    --network-disconnected-text-color: var(--bg-color);
    --cpu-text-color: #89b4fa;
    --memory-text-color: #cba6f7;

    --bar-border-height: 2px;
    --module-padding: 0px 10px;
    --module-margin: 3px 4px;
    --module-radius: 8px;
    --button-radius: 6px;
    --tooltip-radius: 6px;
    --tooltip-padding: 10px;

    background-color: var(--bg-color);
    color: var(--fg-color);
    border-bottom: var(--bar-border-height) solid var(--accent-color);
}

#mode, #clock, #battery, #cpu, #memory, #network, #pulseaudio, #tray, #custom-power, #hyprland-window {
    padding: var(--module-padding);
    margin: var(--module-margin);
    color: var(--fg-color);
    background-color: var(--module-bg-color);
    border-radius: var(--module-radius);
    border: 1px solid var(--module-border-color);
}

#workspaces {
    background-color: var(--module-alt-bg-color);
    padding: 0 3px;
    margin: var(--module-margin);
    border-radius: var(--module-radius);
    border: 1px solid var(--module-hover-bg-color);
}

#workspaces button {
    padding: 2px 8px;
    margin: 2px 1px;
    color: var(--workspace-button-fg-dimmed);
    background-color: var(--module-alt-bg-color);
    border-radius: var(--button-radius);
    border: 1px solid transparent;
    font-weight: bold;
    transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out, border-color 0.2s ease-in-out;
}

#workspaces button.persistent {
    color: var(--workspace-button-fg-persistent);
}

#workspaces button.visible {
    color: var(--fg-color);
    background-color: var(--workspace-button-bg-visible);
}

#workspaces button.focused {
    color: var(--text-hover-color);
    background-color: var(--accent-color);
    border-color: var(--accent-dark-color);
}

#workspaces button.urgent {
    color: var(--urgent-fg-color);
    background-color: var(--urgent-bg-color);
}

#workspaces button:hover {
    color: var(--text-bright-color);
    background-color: var(--module-hover-bg-color);
    border-color: var(--workspace-button-hover-border-color);
}

#workspaces button.visible:hover {
    color: var(--text-bright-color);
    background-color: var(--workspace-button-visible-hover-bg-color);
    border-color: var(--workspace-button-visible-hover-border-color);
}

#workspaces button.focused:hover {
    color: var(--text-hover-color);
    background-color: var(--accent-dark-color);
    border-color: var(--accent-color);
}

#workspaces button.urgent:hover {
    color: var(--urgent-hover-fg-color);
    background-color: var(--urgent-hover-bg-color);
}

#mode {
    background-color: var(--accent-dark-color);
    color: var(--text-hover-color);
    font-weight: bold;
    padding: 0 12px;
}

#hyprland-window {
    color: var(--hyprland-window-text-color);
    font-weight: normal;
    background-color: transparent;
    border: none;
    padding-right: 15px;
}

#clock {
    color: var(--clock-text-color);
    font-weight: bold;
}
#clock:hover {
    color: var(--accent-color);
}

#pulseaudio {
    background-color: var(--module-border-color);
    color: var(--pulseaudio-text-color);
}
#pulseaudio.muted {
    background-color: var(--pulseaudio-muted-bg-color);
    color: var(--pulseaudio-muted-text-color);
}

#network {
    background-color: var(--module-border-color);
    color: var(--network-text-color);
}
#network.disconnected {
    background-color: var(--network-disconnected-bg-color);
    color: var(--network-disconnected-text-color);
}

#cpu {
    background-color: var(--module-border-color);
    color: var(--cpu-text-color);
}
#memory {
    background-color: var(--module-border-color);
    color: var(--memory-text-color);
}

#tray {
    background-color: var(--module-alt-bg-color);
    padding: 0 6px;
    margin-right: 5px;
}

#custom-power {
    color: var(--accent-color);
    background-color: var(--module-bg-color);
    font-size: 16px;
    padding: 0 12px;
}
#custom-power:hover {
    background-color: var(--accent-dark-color);
    color: var(--text-hover-color);
}

tooltip {
    background-color: var(--module-alt-bg-color);
    border: 1px solid var(--accent-color);
    border-radius: var(--tooltip-radius);
    color: var(--fg-color);
    padding: var(--tooltip-padding);
}
tooltip label {
    color: var(--fg-color);
}
EOF
finish_target_file_write "$TARGET_FILE" "Waybar Style"
