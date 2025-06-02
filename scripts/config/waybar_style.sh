#!/usr/bin/env bash
# This script generates the Waybar CSS stylesheet (style.css).
# It defines the visual appearance of the Waybar panel and its modules,
# extensively using CSS variables for easy theming.
# Expected environment variables:
#   WAYBAR_TARGET_DIR: Directory where the 'style.css' file will be placed.
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh" # For prepare_target_file_write, finish_target_file_write

TARGET_FILE="$WAYBAR_TARGET_DIR/style.css"

prepare_target_file_write "$TARGET_FILE" "Waybar Style"

# Generate the Waybar CSS stylesheet using a here document.
cat << 'EOF' > "$TARGET_FILE"
/* Global Resets and Base Styles */
* {
    border: none; /* Reset all borders */
    border-radius: 0; /* Reset all border radii */
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free Solid", sans-serif; /* Default font stack */
    font-size: 14px;
    min-height: 0;
    padding: 0; /* Reset padding */
    margin: 0; /* Reset margin */
}

/* Main Waybar Window Styling */
window#waybar {
    /* --- Theme Color Variables --- */
    /* Base Colors */
    --bg-color: #0a0a0a; /* Main bar background */
    --fg-color: #cccccc; /* Default foreground (text) color */
    --accent-color: #DC143C; /* Main accent color (Crimson) */
    --accent-dark-color: #a0102c; /* Darker shade of accent for hovers/borders */

    /* Module Colors */
    --module-bg-color: #1a1a1a; /* Default background for most modules */
    --module-alt-bg-color: #141414; /* Alternative background (e.g., for workspaces container) */
    --module-border-color: #2c2c2c; /* Border color for modules */
    --module-hover-bg-color: #3d3d3d; /* Background color on module hover */

    /* Text Colors */
    --text-hover-color: #f0f0f0; /* Text color on hover (often brighter) */
    --text-bright-color: #ffffff; /* Very bright text, for emphasis */

    /* Workspace Button Specific Colors */
    --workspace-button-fg-dimmed: #555555; /* Dimmed text for non-focused, non-visible workspaces */
    --workspace-button-fg-persistent: #404040; /* Text for persistent (empty but visible) workspaces */
    --workspace-button-bg-visible: var(--module-border-color); /* Background for visible (but not focused) workspaces */
    --workspace-button-hover-border-color: var(--workspace-button-fg-dimmed);
    --workspace-button-visible-hover-bg-color: #4a4a4a;
    --workspace-button-visible-hover-border-color: #6c7086;

    /* Urgent State Colors (e.g., for urgent workspace) */
    --urgent-bg-color: #FFD700; /* Background for urgent states (e.g., workspace) */
    --urgent-fg-color: #000000; /* Text color for urgent states */
    --urgent-hover-bg-color: #ffec80;
    --urgent-hover-fg-color: var(--bg-color);

    /* Specific Module Text Colors (Examples) */
    --hyprland-window-text-color: #b4befe; /* Color for window title text */
    --clock-text-color: #E6E6FA;           /* Clock text color */
    --pulseaudio-text-color: #fab387;
    --pulseaudio-muted-bg-color: var(--module-hover-bg-color);
    --pulseaudio-muted-text-color: #6c7086;
    --network-text-color: #f9e2af;
    --network-disconnected-bg-color: #f38ba8;
    --network-disconnected-text-color: var(--bg-color);
    --cpu-text-color: #89b4fa;
    --memory-text-color: #cba6f7;

    /* --- Layout & Sizing Variables --- */
    --bar-border-height: 2px;     /* Height of the bottom border of the bar */
    --module-padding: 0px 10px;   /* Padding within each module (top/bottom, left/right) */
    --module-margin: 3px 4px;    /* Margin around each module */
    --module-radius: 8px;         /* Corner radius for modules */
    --button-radius: 6px;         /* Corner radius for buttons (e.g., workspace buttons) */
    --tooltip-radius: 6px;        /* Corner radius for tooltips */
    --tooltip-padding: 10px;      /* Padding within tooltips */

    /* Apply base styles to the bar */
    background-color: var(--bg-color);
    color: var(--fg-color);
    border-bottom: var(--bar-border-height) solid var(--accent-color); /* Prominent bottom border */
}

/* Default Styling for Most Modules */
/* Applies to common modules by their Waybar names (e.g., #clock, #pulseaudio) */
#mode, #clock, #battery, #cpu, #memory, #network, #pulseaudio, #tray, #custom-power, #hyprland-window {
    padding: var(--module-padding);
    margin: var(--module-margin);
    color: var(--fg-color); /* Default text color from theme */
    background-color: var(--module-bg-color); /* Default background from theme */
    border-radius: var(--module-radius);
    border: 1px solid var(--module-border-color);
}

/* Workspace Module Styling */
#workspaces {
    background-color: var(--module-alt-bg-color); /* Slightly different background for the container */
    padding: 0 3px;
    margin: var(--module-margin);
    border-radius: var(--module-radius);
    border: 1px solid var(--module-hover-bg-color); /* Distinct border for the workspace group */
}

#workspaces button {
    padding: 2px 8px; /* Padding inside each workspace button */
    margin: 2px 1px;  /* Margin around each workspace button */
    color: var(--workspace-button-fg-dimmed);
    background-color: var(--module-alt-bg-color); /* Match container or be transparent */
    border-radius: var(--button-radius);
    border: 1px solid transparent; /* Default transparent border */
    font-weight: bold;
    transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out, border-color 0.2s ease-in-out; /* Smooth transitions */
}

#workspaces button.persistent { /* Persistent (empty) workspace button */
    color: var(--workspace-button-fg-persistent);
}

#workspaces button.visible { /* Workspace is on the current output */
    color: var(--fg-color);
    background-color: var(--workspace-button-bg-visible);
}

#workspaces button.focused { /* Currently focused workspace */
    color: var(--text-hover-color);
    background-color: var(--accent-color);
    border-color: var(--accent-dark-color);
}

#workspaces button.urgent { /* Workspace with an urgent hint */
    color: var(--urgent-fg-color);
    background-color: var(--urgent-bg-color);
}

#workspaces button:hover { /* General hover state for workspace buttons */
    color: var(--text-bright-color);
    background-color: var(--module-hover-bg-color);
    border-color: var(--workspace-button-hover-border-color);
}

#workspaces button.visible:hover { /* Hover on a visible (but not focused) workspace */
    color: var(--text-bright-color);
    background-color: var(--workspace-button-visible-hover-bg-color);
    border-color: var(--workspace-button-visible-hover-border-color);
}

#workspaces button.focused:hover { /* Hover on the focused workspace */
    color: var(--text-hover-color);
    background-color: var(--accent-dark-color); /* Darken accent on hover */
    border-color: var(--accent-color);
}

#workspaces button.urgent:hover { /* Hover on an urgent workspace */
    color: var(--urgent-hover-fg-color);
    background-color: var(--urgent-hover-bg-color);
}

/* Specific Module Overrides & Styling */
#mode { /* Hyprland mode indicator (e.g., resize mode) */
    background-color: var(--accent-dark-color);
    color: var(--text-hover-color);
    font-weight: bold;
    padding: 0 12px; /* Custom padding for mode indicator */
}

#hyprland-window { /* Active window title */
    color: var(--hyprland-window-text-color);
    font-weight: normal;
    background-color: transparent; /* No background for window title module */
    border: none; /* No border for window title module */
    padding-right: 15px; /* Extra padding on the right */
}

#clock {
    color: var(--clock-text-color);
    font-weight: bold;
}
#clock:hover { /* Example of specific module hover */
    color: var(--accent-color);
}

#pulseaudio {
    background-color: var(--module-border-color); /* Slightly different background */
    color: var(--pulseaudio-text-color);
}
#pulseaudio.muted { /* Styling for muted state */
    background-color: var(--pulseaudio-muted-bg-color);
    color: var(--pulseaudio-muted-text-color);
}

#network {
    background-color: var(--module-border-color);
    color: var(--network-text-color);
}
#network.disconnected { /* Styling for disconnected state */
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

#tray { /* System tray container */
    background-color: var(--module-alt-bg-color);
    padding: 0 6px; /* Specific padding for tray */
    margin-right: 5px; /* Adjust spacing from the edge or next module */
}

#custom-power { /* Power menu button */
    color: var(--accent-color);
    background-color: var(--module-bg-color);
    font-size: 16px; /* Larger font for icon */
    padding: 0 12px;
}
#custom-power:hover {
    background-color: var(--accent-dark-color);
    color: var(--text-hover-color);
}

/* Tooltip Styling */
tooltip {
    background-color: var(--module-alt-bg-color);
    border: 1px solid var(--accent-color);
    border-radius: var(--tooltip-radius);
    color: var(--fg-color);
    padding: var(--tooltip-padding);
}
tooltip label { /* Text inside tooltips */
    color: var(--fg-color);
}
EOF

finish_target_file_write "$TARGET_FILE" "Waybar Style"
