#!/bin/bash
hypridle \
    timeout 300 'hyprlock' \
    timeout 330 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    timeout 600 'systemctl suspend' \
    before-sleep 'hyprlock && sleep 1' &
