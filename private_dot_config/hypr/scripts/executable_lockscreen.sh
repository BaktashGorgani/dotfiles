#!/usr/bin/env bash

grim -o DP-1 -l 0 /tmp/hyprlock_screenshot1.png & # run this command in background
grim -o DP-2 -l 0 /tmp/hyprlock_screenshot2.png & # idem
grim -o HDMI-A-1 -l 0 /tmp/hyprlock_screenshot3.png & # idem
# wait && # wait background commands to finish. But if hyprlock spawn time (at least until the background image pick step) > the time to take the screeshot(s), you don't have to wait at all :')
hyprlock # so hyprlock will only start when screenshot(s) are done
