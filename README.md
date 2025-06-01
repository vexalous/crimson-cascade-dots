# Personalized Hyprland Dotfiles

## 1. Brief Overview

This repository contains a set of personalized configuration files (dotfiles) for a Linux desktop environment built around the [Hyprland](https://hyprland.org/) Wayland compositor. The aim is to provide a visually appealing, keyboard-driven, and efficient user experience.

Key software configured:

*   **Window Manager:** Hyprland (with various plugins and custom scripts)
*   **Terminal Emulator:** [Alacritty](https://alacritty.org/)
*   **Status Bar:** [Waybar](https://github.com/Alexays/Waybar)
*   **Application Launcher/Powermenu:** [Rofi](https://github.com/davatorium/rofi) (Wayland fork)
*   **Notification Daemon:** Mako
*   **Screen Locker:** Hyprlock
*   **Wallpaper Utility:** Hyprpaper
*   **Clipboard Manager:** cliphist

## 2. Prerequisites

Before you begin, ensure you have the following essential software installed:

### Core Desktop Components
*   **Hyprland** (and its core dependencies)
*   **Alacritty**
*   **Waybar**
*   **Rofi** (Wayland-compatible version)
*   **Mako**
*   **Hyprlock**
*   **Hyprpaper**

### Required Fonts
*   **JetBrainsMono Nerd Font** (for UI and terminal)
*   **Font Awesome** (for icons)

### Essential Utilities & Tools
*   `git` (for cloning this repository)
*   `bash` (for running setup scripts)
*   `jq` (for JSON processing by some scripts)
*   `yad` (for GUI dialogs used by some scripts)
*   `brightnessctl` (for screen brightness control)
*   `playerctl` (for media player control)
*   `wl-paste` & `cliphist` (clipboard utilities)
*   A Polkit agent (e.g., `polkit-kde-agent`, necessary for elevated privileges for some actions)

## 3. Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url> # Replace <repository-url> with the actual URL
    cd <repository-directory> # Replace <repository-directory> with the cloned folder name
    ```

2.  **Run the setup script:**
    Navigate into the cloned directory if you haven't already, then run:
    ```bash
    bash setup.sh
    ```
    The `setup.sh` script will:
    *   **Backup:** Create a timestamped backup of any existing configuration files in `~/.config/` for the applications managed by these dotfiles (e.g., `~/.config/hypr`, `~/.config/alacritty`).
    *   **Copy:** Copy the new configuration files from this repository into your `~/.config/` directory.
    *   It may also set necessary environment variables or permissions for scripts.

## 4. Usage / Post-Installation

*   **Using Configurations:** Once `setup.sh` completes, your new configurations are active in `~/.config/`. Applications like Hyprland, Alacritty, and Waybar will use these new settings automatically upon their next launch.
*   **Reloading:**
    *   **Hyprland:** To apply changes to Hyprland without logging out, you can usually reload its configuration using a keybinding (often `Super + M` or `Super + Shift + R` - check `~/.config/hypr/conf/keybinds.conf` for the exact binding).
    *   **Waybar:** Waybar typically reloads automatically when its configuration file (`~/.config/waybar/config`) or stylesheet (`~/.config/waybar/style.css`) is saved. If not, you may need to kill and restart the Waybar process.
*   **Detailed Configuration:**
    *   For Alacritty details, see: `alacritty/README.md` (in this repository, corresponding to `~/.config/alacritty/`)
    *   For Hyprland details, see: `hypr/README.md` (in this repository, corresponding to `~/.config/hypr/`)
    *   For Waybar details, see: `waybar/README.md` (in this repository, corresponding to `~/.config/waybar/`)

## 5. Basic Customization

For most users, customization involves editing the configuration files directly after the setup script has run:

*   Navigate to your `~/.config/` directory.
*   Edit files like `~/.config/hypr/hyprland.conf`, `~/.config/alacritty/alacritty.toml`, or `~/.config/waybar/config` using your preferred text editor.
*   Changes made here are local to your system and will be active once the respective application is reloaded or restarted.

This method is straightforward and recommended for tweaking settings to your personal preference.

## 6. Advanced Customization & Development

This repository also contains scripts that were used to *generate* the configuration files. This is for users who want to modify the underlying logic of how configurations are built, or contribute to the development of these dotfiles.

*   The generation scripts are located in the `scripts/config/` directory within the cloned repository.
*   These scripts take template files or use helper libraries (in `scripts/config_lib/`) to produce the final configuration files found in `hypr/`, `alacritty/`, etc.
*   For detailed information on how to use these scripts, their structure, and contribution guidelines for them, please refer to `scripts/README.md`.
*   **Caution:** Modifying and running these generator scripts will overwrite the configuration files within the repository itself.

## 7. Troubleshooting

*   **Fonts not displaying correctly (especially icons):**
    *   Ensure JetBrainsMono Nerd Font and Font Awesome are installed and recognized.
    *   You might need to rebuild your font cache: `fc-cache -fv`.
*   **Scripts not executing:**
    *   The `setup.sh` script attempts to set execute permissions. If issues persist, ensure scripts in `~/.config/hypr/scripts/` (and other relevant locations) are executable: `chmod +x ~/.config/hypr/scripts/*.sh`.
*   **Changes not applying:**
    *   **Hyprland:** Reload configuration (e.g., `Super + M`).
    *   **Waybar:** Should reload on config save. If not, restart Waybar (e.g., `killall waybar && waybar &`).
    *   **Alacritty:** New settings apply to newly opened terminal windows.
*   **Missing dependencies:** If applications fail to start or features are missing, double-check the "Prerequisites" section and ensure all listed software is installed.

## 8. Repository Structure

A brief overview of the main directories in this repository:

```
.
├── README.md               # This file
├── LICENSE                 # License information
├── .stylelintrc.json       # Stylelint configuration for Waybar CSS
├── alacritty/              # Alacritty terminal configuration
│   ├── README.md
│   └── alacritty.toml
├── hypr/                   # Hyprland window manager configuration
│   ├── README.md
│   ├── conf/               # Hyprland config snippets
│   ├── hyprland.conf       # Main Hyprland configuration file
│   └── scripts/            # Helper scripts for Hyprland
├── scripts/                # Setup and configuration generation scripts
│   ├── README.md
│   ├── config/             # Scripts to GENERATE dotfiles
│   ├── config_lib/         # Libraries for config generation
│   ├── setup_lib/          # Libraries for setup.sh
│   └── setup.sh            # Main setup script
├── waybar/                 # Waybar status bar configuration
│   ├── README.md
│   ├── config
│   └── style.css
├── crimson_black_wallpaper.png # Example wallpaper
```

## 9. Contributing

Contributions are welcome!

*   Fork the repository.
*   Create a new branch for your feature or bug fix.
*   Make your changes.
    *   If modifying basic configurations (e.g., `hypr/hyprland.conf`), ensure your changes are well-tested.
    *   If modifying the generation scripts in `scripts/config/`, please also regenerate the relevant output configuration files and commit them. Ensure you've read `scripts/README.md`.
*   Open a pull request with a clear description of your changes.
*   Please report any issues or suggest improvements by opening an issue on the GitHub repository.

## 10. License

This project is released into the public domain. See the [LICENSE](LICENSE) file for details, which is based on the [Unlicense](https://unlicense.org).
