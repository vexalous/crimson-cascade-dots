# Hyprland Configuration

This directory contains the configuration files and helper scripts for the Hyprland Wayland compositor.

## Directory Structure

*   `hyprland.conf`: The main configuration file for Hyprland. It sources other specific configuration files from the `conf/` directory.
*   `conf/`: Contains modular configuration files for different aspects of Hyprland:
    *   `animations.conf`: Configures window animations, borders, and layout visuals.
    *   `decorations.conf`: Manages window decorations like shadows and rounding.
    *   `env.conf`: Sets environment variables for the Hyprland session.
    *   `execs.conf`: Defines commands and applications to be executed at startup.
    *   `general.conf`: General Hyprland settings like gaps, border sizes, and layout.
    *   `input_gestures.conf`: Configures input devices (keyboard, mouse, touchpad) and gestures.
    *   `keybinds.conf`: Defines custom key bindings for various actions.
    *   `layouts.conf`: Specifies different layout options (e.g., dwindle, master).
    *   `misc.conf`: Miscellaneous settings that don't fit into other categories.
    *   `windowrules.conf`: Sets rules for specific windows (e.g., floating, opacity, size).
*   `rofi/`:
    *   `powermenu_theme.rasi`: A Rofi theme configuration for the power menu script.
*   `scripts/`: Contains helper scripts used by Hyprland for various functionalities:
    *   `brightness_notify.sh`: Script to adjust screen brightness and show notifications.
    *   `colors.sh`: (Potentially for managing color schemes - needs review)
    *   `idle_config.sh`: Configures `swayidle` for idle actions like screen locking.
    *   `notify.sh`: A general-purpose notification script.
    *   `rofi_powermenu.sh`: Displays a power menu (shutdown, reboot, logout, lock) using Rofi.
    *   `volume_notify.sh`: Script to adjust audio volume and show notifications.

## Main Configuration (`hyprland.conf`)

The `hyprland.conf` file is the entry point for Hyprland's configuration. It primarily uses the `source=` directive to include the more specific `.conf` files from the `conf/` subdirectory. This modular approach helps in keeping the configuration organized and easier to manage.

## Scripts

The scripts in the `scripts/` directory enhance Hyprland's functionality. They are typically invoked via key bindings defined in `keybinds.conf` or as part of system events.

*   **Brightness Control**: `brightness_notify.sh` likely uses `brightnessctl` or a similar utility.
*   **Volume Control**: `volume_notify.sh` likely uses `pactl` or `amixer`.
*   **Power Menu**: `rofi_powermenu.sh` provides a user-friendly way to manage system power states.
*   **Idle Management**: `idle_config.sh` sets up `swayidle` with `hyprlock` for automatic screen locking after a period of inactivity and before sleep.

## Customization

To customize Hyprland:

1.  **Modify `hyprland.conf`**: If you need to change which configuration files are sourced or add top-level settings.
2.  **Edit files in `conf/`**: For specific adjustments to animations, key bindings, window rules, etc.
3.  **Modify scripts in `scripts/`**: If you want to change the behavior of helper scripts (e.g., notification style, power menu options).
4.  **Update Rofi theme**: Edit `rofi/powermenu_theme.rasi` to change the appearance of the power menu.

Refer to the [official Hyprland documentation](https://wiki.hyprland.org/) for detailed information on configuration options and syntax.
