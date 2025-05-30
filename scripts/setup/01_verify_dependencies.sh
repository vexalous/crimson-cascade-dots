#!/bin/bash

echo "--- Checking Core Dependencies ---"

core_packages=(
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "waybar"
    "rofi"
    "alacritty"
    "mako"
    "ttf-jetbrains-mono-nerd"
    "ttf-font-awesome"
    "brightnessctl"
    "pulseaudio-utils"
    "grim"
    "slurp"
    "swappy"
    "jq"
    "cliphist"
    "polkit-kde-authentication-agent"
    "bibata-cursor-theme"
    "xsettingsd" 
    "pavucontrol"
    "nm-connection-editor"
    "btop"
    "wlogout"
)

missing_packages=()
all_installed=true

echo "Checking for installed packages..."
for pkg in "${core_packages[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        missing_packages+=("$pkg")
        all_installed=false
    else
        : 
    fi
done

if [ "$all_installed" = true ]; then
    echo "All listed core dependencies appear to be installed."
    echo ""
else
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!! WARNING: The following core dependencies appear to be MISSING: !!"
    for missing_pkg in "${missing_packages[@]}"; do
        echo "!!   - $missing_pkg"
    done
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    echo "Please install them using pacman or your AUR helper (e.g., yay)."
    echo "Example: sudo pacman -S <package_name> OR yay -S <package_name>"
    echo ""
    read -p "Abort setup to install missing packages? (Y/n): " abort_choice
    abort_choice=$(echo "$abort_choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$abort_choice" == "y" || "$abort_choice" == "" ]]; then
        echo "Aborting setup. Please install missing packages."
        exit 1
    else
        echo "Proceeding with setup, but some components might not work correctly."
    fi
fi

echo "Dependency check section complete."
echo ""
