# Dotfiles Repository

This repository contains a collection of personal dotfiles and configurations for a customized Linux desktop environment.

## Overview

This setup is built around the following core components:

*   **Window Manager**: Hyprland (Wayland compositor)
*   **Terminal Emulator**: Alacritty
*   **Application Launcher**: Rofi
*   **Status Bar**: Waybar
*   **Shell**: Bash (with custom scripts)

The goal of this repository is to provide a consistent and personalized desktop experience.

## Structure

*   `alacritty/`: Configuration for the Alacritty terminal emulator.
*   `hypr/`: Configuration and scripts for the Hyprland window manager.
    *   `hypr/conf/`: Individual configuration files for different aspects of Hyprland.
    *   `hypr/rofi/`: Rofi theme for the powermenu.
    *   `hypr/scripts/`: Helper scripts for Hyprland functionalities (e.g., brightness, volume, notifications).
*   `scripts/`: General-purpose shell scripts and configuration management tools.
    *   `scripts/config/`: Scripts to manage and apply configurations for various applications.
    *   `scripts/config_lib/`: Library scripts with common functions for configuration management.
    *   `scripts/setup_lib/`: Library scripts for setup tasks (e.g., backups, dependency installation).
*   `waybar/`: Configuration and styling for the Waybar status bar.
*   `setup.sh`: Main script for setting up the dotfiles and installing dependencies.
*   `LICENSE`: The license for this repository.
*   `.stylelintrc.json`: Configuration for stylelint (CSS linter).

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```
2.  **Run the setup script:**
    ```bash
    ./setup.sh
    ```
    This script will:
    *   Install necessary dependencies (you might be prompted for your password).
    *   Create backups of existing configuration files.
    *   Symlink the dotfiles in this repository to their appropriate locations (e.g., `~/.config/hypr`, `~/.config/alacritty`).

**Note:** Review the `setup.sh` script and the scripts in `scripts/setup_lib/` before running to understand the actions it will perform. It's always a good idea to back up your existing dotfiles manually before proceeding.

## Dependencies

The `setup.sh` script attempts to install most dependencies. However, key dependencies include:

*   Hyprland
*   Alacritty
*   Rofi
*   Waybar
*   Necessary fonts (check Waybar and Alacritty configurations)
*   `jq` (for JSON processing in scripts)
*   `stylelint` (if you plan to modify Waybar CSS)
*   Various utilities for scripts (e.g., `brightnessctl`, `pactl`, `playerctl`, `swayidle`, `hyprlock`, `hyprpaper`)

Refer to the individual component's documentation for their specific dependencies.

## Customization

Feel free to fork this repository and customize the configurations to your liking. The scripts in `scripts/config/` are designed to be somewhat modular, allowing you to manage different parts of the configuration.

## Contributing

While these are personal dotfiles, suggestions and improvements are welcome. Please open an issue to discuss any changes.

## License

This project is licensed under the terms of the LICENSE file.
