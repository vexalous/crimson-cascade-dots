# My Personalized Dotfiles for a Hyprland Environment

This repository contains my personal configuration files (dotfiles) for a Linux desktop environment centered around the Hyprland Wayland compositor. It also includes scripts for setting up and managing these configurations.

## Overview

These dotfiles provide a customized experience for:

*   **Window Manager:** [Hyprland](https://hyprland.org/) (with various plugins and custom scripts)
*   **Terminal Emulator:** [Alacritty](https://alacritty.org/)
*   **Status Bar:** [Waybar](https://github.com/Alexays/Waybar)
*   **Application Launcher/Powermenu:** [Rofi](https://github.com/davatorium/rofi) (Wayland fork)
*   **Notification Daemon:** Mako
*   **Screen Locker:** Hyprlock
*   **Wallpaper Utility:** Hyprpaper
*   **Clipboard Manager:** cliphist

The goal is to create a visually appealing, keyboard-driven, and efficient desktop environment.

## Prerequisites


*   **Hyprland** and its dependencies.
*   **Alacritty**
*   **Waybar**
*   **Fonts:**
    *   JetBrainsMono Nerd Font (for general UI and terminal)
    *   Font Awesome (for icons)
*   **Essential Utilities:**
    *   `git` (to clone this repository)
    *   `jq` (for JSON processing, used by some scripts)
    *   `yad` (for GUI dialogs in scripts)
    *   `brightnessctl` (for backlight/brightness control)
    *   `playerctl` (for media player control)
    *   `mako` (notification daemon)
    *   `hyprlock` (screen locker)
    *   `hyprpaper` (wallpaper utility)
    *   `wl-paste` & `cliphist` (clipboard utilities)
    *   A Polkit agent (e.g., `polkit-kde-agent` or similar, for elevated privileges)
*   **Shell:** `bash` (for running setup scripts)

## Installation

1.  **Clone the repository:**
    ```bash

2.  **Run the setup script:**
    ```bash
    bash setup.sh
    ```
    This script will:
    *   Back up any existing configuration files in `~/.config/` for the applications managed by these dotfiles (e.g., `~/.config/hypr`, `~/.config/alacritty`, etc.) to a timestamped backup directory.
    *   Copy the configuration files from this repository into your `~/.config/` directory.
    *   Set necessary environment variables (e.g., for Hyprland scripts).

## How it Works

This repository is structured to provide ready-to-use configurations while also offering a way to understand and regenerate them.

### Hyprland (`hypr/`)

*   The core window manager.
*   Configuration is split into multiple files within `hypr/conf/` for better organization (e.g., `keybinds.conf`, `animations.conf`, `windowrules.conf`).
*   `hyprland.conf` sources these individual files.
*   Extensive use of custom scripts in `hypr/scripts/` for enhanced functionality.
*   See `hypr/README.md` for detailed information on structure, keybinds, and customization.

### Rofi (`hypr/rofi/`)

*   Used for the application launcher and a custom power menu (`rofi_powermenu.sh`).
*   Theming is done via `hypr/rofi/powermenu_theme.rasi`.
*   No separate Rofi configuration directory; it's integrated with Hyprland's scripts and theming.

### Waybar (`waybar/`)

*   Highly customizable status bar.
*   Configuration is in `waybar/config` (JSON format).
*   Styling is done via `waybar/style.css`.
*   Modules are configured to display workspace information, clock, system tray, hardware status (CPU, RAM, disk), volume, network, etc.
*   See `waybar/README.md` for details on modules and styling.

## Customization

There are two main ways to customize these dotfiles:

1.  **Post-Setup Modification (Recommended for most users):**
    *   After running `setup.sh`, the configuration files will be in your `~/.config/` directory (e.g., `~/.config/hypr/hyprland.conf`, `~/.config/waybar/config`).
    *   You can directly edit these files to make changes. This is the simplest way to tweak settings to your liking.
    *   Changes made here will not affect the files in your cloned repository unless you manually copy them back.

2.  **Modifying Generator Scripts (Advanced):**
    *   If you want to change the fundamental structure or generation logic of the configurations, you can modify the scripts in the `scripts/config/` directory within your cloned repository.
    *   After making changes, you would run the relevant script (e.g., `bash scripts/config/hyprland_main.sh`) from the root of the repository to regenerate the configuration files (e.g., `hypr/hyprland.conf`).
    *   These changes can then be committed to your fork of the repository.
    *   **Caution:** Be careful when running these scripts, as they will overwrite the existing configurations in the repository.

## Troubleshooting

*   **Fonts not displaying correctly (especially icons):** Ensure you have JetBrainsMono Nerd Font and Font Awesome installed and correctly recognized by your system. You might need to rebuild your font cache (`fc-cache -fv`).
*   **Scripts not executing:** Some scripts (especially those in `hypr/scripts/`) might require execute permissions. The `setup.sh` script attempts to handle this, but you can manually set them if needed: `chmod +x ~/.config/hypr/scripts/*.sh`.
*   **Changes not applying:**
    *   For Hyprland, reload the configuration (usually `Super + M` or as defined in your `hypr/conf/keybinds.conf`).
    *   For Waybar, it usually reloads automatically upon saving its config/style file. If not, you might need to kill and restart it.
    *   For Alacritty, new settings apply to newly opened terminals.

## Repository Structure

```
.
├── README.md               # This file
├── LICENSE                 # License information
├── .stylelintrc.json       # Stylelint configuration for Waybar CSS
├── alacritty/              # Alacritty configuration
│   ├── README.md
│   └── alacritty.toml
├── hypr/                   # Hyprland configuration
│   ├── README.md
│   ├── conf/               # Main Hyprland config snippets
│   ├── hyprland.conf       # Main Hyprland configuration file (sources from conf/)
│   └── scripts/            # Helper scripts for Hyprland
├── scripts/                # Setup and configuration generation scripts
│   ├── README.md
│   ├── config/             # Scripts to GENERATE the dotfiles in this repo
│   ├── config_lib/         # Libraries for config generation scripts
│   ├── setup_lib/          # Libraries for the main setup.sh script
│   └── setup.sh            # Main setup script for end-users
├── waybar/                 # Waybar configuration
│   ├── README.md
└── crimson_black_wallpaper.png # Example wallpaper
```

## Contributing

Feel free to fork this repository, make improvements, and open pull requests. If you find any issues or have suggestions, please open an issue on the GitHub repository.

When contributing, if you modify the configuration generation logic in `scripts/config/`, please ensure you regenerate the relevant configuration files and commit them as well.

## License
