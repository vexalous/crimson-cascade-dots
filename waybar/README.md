# Waybar Configuration

This directory contains the configuration and styling for the Waybar status bar.

## Files

*   `config`: This is the main configuration file for Waybar, typically in JSON format. It defines:
    *   The modules to be displayed on the bar (e.g., clock, workspaces, network, volume, battery).
    *   The order and alignment of modules.
    *   Specific settings for each module (e.g., format strings, icons, click actions).
    *   General Waybar settings (e.g., position, height, layer).
*   `style.css`: This file contains the CSS rules used to style Waybar and its modules. You can customize:
    *   Fonts, colors, backgrounds.
    *   Margins, padding, borders.
    *   Icon styles.
    *   Appearance of specific modules using their names or CSS classes/IDs defined in the `config` file.

## Customization

1.  **Editing `config`**:
    *   To add, remove, or reorder modules, modify the main JSON array (often `modules-left`, `modules-center`, `modules-right`).
    *   To change a module's behavior or appearance through its configuration, find its entry in the JSON and adjust its properties. For example, you can change the date/time format for the clock module or the icons used for the workspace module.
    *   Refer to the [Waybar Wiki](https://github.com/Alexays/Waybar/wiki/Configuration) for a full list of modules and their configuration options.

2.  **Editing `style.css`**:
    *   To change the visual appearance (colors, fonts, spacing), modify the CSS rules in `style.css`.
    *   You can target Waybar itself (`#waybar` window selector) or specific modules (e.g., `#clock`, `#network`, `.custom-module`). Module names from the `config` file are often usable as CSS IDs.
    *   Use your browser's developer tools (inspect element) on a running Waybar instance (if possible, though Waybar renders directly) or refer to online CSS resources to experiment with styles.
    *   The [Waybar Wiki on Styling](https://github.com/Alexays/Waybar/wiki/Styling) provides guidance on how to apply styles.

## Applying Changes

After modifying `config` or `style.css`, you typically need to reload Waybar for the changes to take effect. This can often be done by:

*   Sending a `SIGUSR2` signal to the Waybar process: `killall -SIGUSR2 waybar`
*   Restarting Waybar through your window manager's startup mechanism or a key binding if you have one configured.

Check your Hyprland key bindings (`hypr/conf/keybinds.conf`) or startup scripts (`hypr/conf/execs.conf`) for how Waybar is launched and if there's a reload command configured.
