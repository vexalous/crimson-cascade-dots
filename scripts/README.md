# Scripts

This directory contains various shell scripts for managing configurations, automating tasks, and providing helper functionalities for the desktop environment.

## Subdirectories

*   `config/`: Contains scripts specifically designed to manage and apply configurations for different applications (e.g., Alacritty, Hyprland, Waybar). These scripts might handle symlinking dotfiles, setting up environment variables, or applying themes.
*   `config_lib/`: Contains library scripts with common shell functions used by the configuration scripts in `config/`. This promotes code reuse and modularity.
*   `setup_lib/`: Contains library scripts with functions used by the main `setup.sh` script. These scripts handle tasks such as:
    *   Backing up existing files (`backup.sh`).
    *   Installing dependencies (`dependencies.sh`).
    *   Performing file system operations like creating directories and symlinks (`fs_ops.sh`).
    *   Git-related operations (`git_ops.sh`).
    *   User interface utilities for the setup script (e.g., prompts, messages) (`ui.sh`).

## Individual Scripts

Any scripts directly within this `scripts/` directory (if any) would be general-purpose utilities not fitting into the `config` or `setup_lib` categories. (Currently, it seems most scripts are organized into the subdirectories).

## Usage

*   **Configuration Scripts (`config/`)**: These are typically invoked by the main `setup.sh` script or can be run individually if you need to re-apply a specific configuration. For example, `scripts/config/hyprland_main.sh` might be responsible for setting up the core Hyprland configuration.
*   **Library Scripts (`config_lib/`, `setup_lib/`)**: These are not meant to be run directly. They provide functions sourced by other scripts.
*   **Main Setup Script (`../setup.sh`)**: The primary entry point for setting up the dotfiles is the `setup.sh` script in the parent directory. It utilizes the scripts within `setup_lib/` and `config/` to perform the complete setup process.

## Customization

If you need to modify how configurations are applied or how the initial setup works, you'll likely need to edit the scripts within these directories.

*   For changes to the setup process (e.g., adding new dependencies, changing backup locations), look into `setup_lib/` and the main `setup.sh`.
*   For changes to how specific application configurations are managed, explore the relevant scripts in `config/`.
*   If you want to add new shared functionality, consider adding functions to `config_lib/common.sh` or creating a new library script.

Always be cautious when modifying shell scripts, and ensure you understand the commands being executed, especially those requiring `sudo` permissions or performing file system modifications.
