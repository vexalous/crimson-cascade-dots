# Personalized Hyprland Dotfiles

## Brief Overview

This repository contains a set of personalized configuration files (dotfiles) for a Linux desktop environment built around the [Hyprland](https://hyprland.org/) Wayland compositor. It's primarily aimed at Linux enthusiasts and users who prefer a highly customized, keyboard-driven, and efficient workflow. The aim is to provide a visually appealing and performant user experience.

Key software configured:

*   **Window Manager:** Hyprland (with various plugins and custom scripts)
*   **Terminal Emulator:** [Alacritty](https://alacritty.org/)
*   **Status Bar:** [Waybar](https://github.com/Alexays/Waybar)
*   **Application Launcher/Powermenu:** [Rofi](https://github.com/Alexays/rofi) (Wayland fork)
*   **Notification Daemon:** [Mako](https://github.com/emersion/mako)
*   **Screen Locker:** [Hyprlock](https://github.com/hyprwm/hyprlock)
*   **Wallpaper Utility:** [Hyprpaper](https://github.com/hyprwm/hyprpaper)
*   **Clipboard Manager:** [cliphist](https://github.com/sentriz/cliphist)

## Repository Structure

A brief overview of the main directories in this repository:

```text
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

## Prerequisites

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
    *   Download from [Nerd Fonts](https://www.nerdfonts.com/font-downloads).
    *   Installation methods vary by OS (e.g., manual copy, using a package manager if available for your distribution like `AUR` on Arch Linux, or Homebrew on macOS). Refer to Nerd Fonts documentation or your OS's font installation guides.
*   **Font Awesome** (for icons)
    *   Typically installed as a desktop font. Download and instructions can be found at [Font Awesome Desktop Setup](https://fontawesome.com/docs/desktop/setup/get-started).
    *   Follow their instructions for downloading and installing the font files on your system, or use a package manager if available.

### Essential Utilities & Tools
*   `git` (for cloning this repository)
*   `bash` (for running setup scripts)
*   `jq` (for JSON processing by some scripts)
*   `yad` (for GUI dialogs used by some scripts)
*   `brightnessctl` (for screen brightness control)
*   `playerctl` (for media player control)
*   `wl-paste` & `cliphist` (clipboard utilities)
*   A Polkit agent (e.g., `polkit-kde-agent`, necessary for elevated privileges for some actions)

## Installation

1.  **Clone the repository:**
    Using HTTPS:
    ```bash
    git clone https://github.com/vexalous/crimson-cascade-dots.git
    cd crimson-cascade-dots
    ```
    Alternatively, using SSH:
    ```bash
    git clone git@github.com:vexalous/crimson-cascade-dots.git
    cd crimson-cascade-dots
    ```

2.  **Run the setup script:**
    Navigate into the cloned directory if you haven't already, then run:
    ```bash
    bash setup.sh
    ```
    The `setup.sh` script will:
      * **Backup:** Create a timestamped backup of any existing configuration files in `~/.config/` for the applications managed by these dotfiles (e.g., `~/.config/hypr`, `~/.config/alacritty`).
      * **Copy:** Copy the new configuration files from this repository into your `~/.config/` directory.
      * It may also set necessary environment variables or permissions for scripts.

## Usage and Customization

*   **Using Configurations:** Once `setup.sh` completes, your new configurations are active in `~/.config/`. Applications like Hyprland, Alacritty, and Waybar will use these new settings automatically upon their next launch.
*   **Reloading Configurations:**
    *   **Hyprland:** To apply changes to Hyprland without logging out, you can usually reload its configuration using a keybinding (often `Super + M` or `Super + Shift + R` - check `~/.config/hypr/conf/keybinds.conf` for the exact binding).
    *   **Waybar:** Waybar typically reloads automatically when its configuration file (`~/.config/waybar/config`) or stylesheet (`~/.config/waybar/style.css`) is saved. If not, you may need to kill and restart the Waybar process.
    *   **Alacritty:** New settings generally apply to newly opened terminal windows.
*   **Basic Customization:** For most users, further customization involves editing the configuration files directly in your `~/.config/` directory (e.g., `~/.config/hypr/hyprland.conf`, `~/.config/alacritty/alacritty.toml`, etc.) using your preferred text editor. Changes made here are local to your system and will be active once the respective application is reloaded or restarted.
*   **Detailed Configuration:** For more in-depth information on configuring specific applications, refer to their respective `README.md` files within this repository (e.g., `hypr/README.md`, `alacritty/README.md`, `waybar/README.md`). These files provide more component-specific details.

## Advanced Customization & Development

This repository also contains scripts that were used to *generate* the configuration files. This is for users who want to modify the underlying logic of how configurations are built, or contribute to the development of these dotfiles.

*   The generation scripts are located in the `scripts/config/` directory within the cloned repository.
*   These scripts take template files or use helper libraries (in `scripts/config_lib/`) to produce the final configuration files found in `hypr/`, `alacritty/`, etc.
*   For detailed information on how to use these scripts, their structure, and contribution guidelines for them, please refer to `scripts/README.md`.
*   **Caution:** Modifying and running these generator scripts will overwrite the configuration files within the repository itself.

## Troubleshooting

*   **Fonts not displaying correctly (especially icons):**
    *   Ensure JetBrainsMono Nerd Font and Font Awesome are installed and recognized.
    *   You might need to rebuild your font cache: `fc-cache -fv`.
*   **Scripts not executing:**
    *   The `setup.sh` script attempts to set execute permissions for scripts it knows about. If you have custom scripts or encounter issues, ensure your scripts (e.g., in `~/.config/hypr/scripts/` or other custom paths) are executable: `chmod +x /path/to/your/script.sh`.
*   **Changes not applying:**
    *   **Hyprland:** Reload configuration (e.g., `Super + M`).
    *   **Waybar:** Should reload on config save. If not, restart Waybar (e.g., `killall waybar && waybar &`).
    *   **Alacritty:** New settings apply to newly opened terminal windows.
*   **Missing dependencies:** If applications fail to start or features are missing, double-check the "Prerequisites" section and ensure all listed software is installed.

## Contributing

Contributions are welcome!

*   Fork the repository.
*   Create a new branch for your feature or bug fix.
*   Make your changes.
    *   If modifying basic configurations (e.g., `hypr/hyprland.conf`), ensure your changes are well-tested.
    *   If modifying the generation scripts in `scripts/config/`, please also regenerate the relevant output configuration files and commit them. Ensure you've read `scripts/README.md`.
*   Open a pull request with a clear description of your changes.
*   Please report any issues or suggest improvements by opening an issue on the GitHub repository.

## License

This project is released into the public domain. See the [LICENSE](LICENSE) file for details, which is based on the [Unlicense](https://unlicense.org).
