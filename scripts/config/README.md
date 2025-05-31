# Configuration Generation Scripts

The shell scripts in this directory (`scripts/config/`) are primarily intended for **developers** to generate or update the configuration files that are stored within the main repository (e.g., in the `hypr/`, `alacritty/`, `waybar/` directories).

**These scripts are generally NOT part of the end-user `setup.sh` process, which typically copies the pre-generated configuration files from the repository to the system's configuration directories (e.g., `$HOME/.config/`).**

## Purpose

-   To automate the creation of various configuration files.
-   To maintain consistency if parts of the configuration are derived or templated (though many currently generate static content).
-   To provide a centralized way to manage the structure and content of the committed configuration files.

## Usage (for Developers)

When running these scripts manually or via a custom developer script, you'll typically need to set environment variables to control the output locations relative to the repository root. For example:

*   `CONFIG_TARGET_DIR`: Should generally be set to the root of this repository (e.g., `CONFIG_TARGET_DIR=.`).
*   `HYPR_CONF_TARGET_DIR`: Should be set to the target directory for Hyprland's specific `.conf` snippets, relative to `CONFIG_TARGET_DIR` (e.g., `HYPR_CONF_TARGET_DIR=\$CONFIG_TARGET_DIR/hypr/conf` or `HYPR_CONF_TARGET_DIR=./hypr/conf`).
*   Other `*_TARGET_DIR` variables might be used by other scripts similarly.

For instance, to regenerate the `hypr/hyprland.conf` file and its associated `*.conf` files within the repository, a developer might run a wrapper script that sets these variables appropriately before invoking the relevant scripts from this directory (like `hyprland_main.sh`, `hyprland_general.sh`, etc.).

**Example:**
To run `hyprland_general.sh` to regenerate `hypr/conf/general.conf` in the repo:
```bash
CONFIG_TARGET_DIR=. HYPR_CONF_TARGET_DIR=./hypr/conf ./scripts/config/hyprland_general.sh
```

Review each script for the specific environment variables it uses for output paths. The scripts typically use helper functions from `scripts/config_lib/common.sh` which log the target files being written.
