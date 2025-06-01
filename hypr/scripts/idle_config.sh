#!/usr/bin/env bash
# This script configures hypridle, a daemon for managing idle states in Hyprland.
# It sets up screen locking, display power management (DPMS), and system suspend.
set -euo pipefail

# Launch hypridle with the following configurations:
hypridle \
    timeout 300 'hyprlock' \                       # After 300 seconds (5 minutes) of inactivity, lock the screen using hyprlock.
    timeout 330 'hyprctl dispatch dpms off' \       # After 330 seconds (5.5 minutes) of inactivity, turn off the display (DPMS).
    resume 'hyprctl dispatch dpms on' \             # When activity resumes, turn the display back on.
    timeout 600 'systemctl suspend' \               # After 600 seconds (10 minutes) of inactivity, suspend the system.
    before-sleep 'hyprlock && sleep 1' &             # Before going to sleep (suspend), lock the screen and wait for 1 second to ensure locking.
                                                     # The '&' at the end backgrounds the hypridle process.
