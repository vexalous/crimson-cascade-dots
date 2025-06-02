# Alacritty Configuration

This directory houses the `alacritty.toml` file, which configures the Alacritty terminal emulator. This configuration is tailored to provide a consistent and visually appealing experience within the Crimson Cascade dotfiles environment.

## Key Configuration Features

The `alacritty.toml` in this repository sets various options, including:

*   **Font:** Utilizes "JetBrainsMono Nerd Font" for clear readability and icon support, consistent with the overall setup. The font size is also pre-configured.
*   **Color Scheme:** Implements a specific dark color scheme (background `#0a0a0a`, foreground `#e0e0e0`, with `#FF244C` as a primary accent) to match the visual theme of the dotfiles.
*   **Opacity:** Sets a slight transparency for the terminal window (`opacity = 0.94`) for a modern desktop feel.
*   **Padding:** Default padding around the terminal content is defined.
*   **Key Bindings:** Includes standard keybindings for actions like copy (`Ctrl+Shift+C`) and paste (`Ctrl+Shift+V`).
*   **Performance:** May include other standard performance-related settings.

## Customization

You are encouraged to customize Alacritty's appearance and behavior further by editing the `alacritty.toml` file located in `~/.config/alacritty/` (after running the main setup script).

*   For a comprehensive list of available options and their usage, refer to the [official Alacritty documentation](https://alacritty.org/config-alacritty.html).
*   Changes are typically applied automatically when you save the `alacritty.toml` file. In some instances, restarting Alacritty might be necessary for all changes to take effect.

Remember that modifications made to `~/.config/alacritty/alacritty.toml` are local to your system. If you wish to contribute changes back to this repository, you would need to update the file within your cloned repository directory.
