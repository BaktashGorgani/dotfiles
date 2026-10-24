#!/bin/bash
# Required programs: ncat, systemctl
#
# Watches Hyprland's event socket (.socket2.sock) for monitor hotplug
# events and restarts gammastep.service whenever one fires. gammastep
# only applies its color temperature to the outputs that existed at the
# moment it connected to Wayland, so a monitor that is (re)connected
# afterwards (e.g. a loose cable being reseated) never gets the
# adjustment until gammastep is restarted. This script exists to
# automate that restart.
#
# This is meant to be run as a persistent systemd --user service
# (see gammastep-hotplug-watch.service), not invoked manually.

PROGRAMS=(ncat systemctl)
for PROGRAM in "${PROGRAMS[@]}"; do
    if ! hash "$PROGRAM" 2>/dev/null; then
        echo "Error: $PROGRAM is not installed." >&2
        exit 2
    fi
done

# systemd --user services don't reliably inherit the Hyprland session
# environment, so hyprctl/the IPC socket can't be located from
# HYPRLAND_INSTANCE_SIGNATURE alone. Rebuild the minimal environment
# needed, same approach as change_wallpaper.bash.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" && -d "$XDG_RUNTIME_DIR/hypr" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -n1)
    export HYPRLAND_INSTANCE_SIGNATURE
fi

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" || ! -S "$SOCKET" ]]; then
    echo "Error: Cannot find Hyprland event socket at '$SOCKET'. Is Hyprland running?" >&2
    exit 1
fi

echo "Watching $SOCKET for monitor hotplug events..."

# Reconnect in a loop in case Hyprland restarts and the socket drops.
while true; do
    ncat -U "$SOCKET" | while IFS= read -r LINE; do
        case "$LINE" in
            monitoradded*|monitoraddedv2*)
                echo "Monitor hotplug event ('$LINE'); restarting gammastep.service"
                systemctl --user restart gammastep.service
                ;;
        esac
    done
    echo "Connection to $SOCKET closed; retrying in 2s..."
    sleep 2
done
