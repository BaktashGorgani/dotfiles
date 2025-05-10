#!/usr/bin/bash
# This script uses grimshot to take a screenshot and save it to a file. The file is saved in the $HOME/Pictures/Screenshots directory with a name that includes the current date and time.
# The script then uses swappy as an image editor. If the image was edited, the original file is deleted and the edited file is saved in the $HOME/Pictures/Screenshots directory with a name that includes the current date and time.
# The script sends a notification with the result.
#
#
# Make the script executable: 
# chmod +x <path-to-script>
#
#
# Add a keybinding to the script in the  ~/.config/hypr/hypr.conf  file:
# example:
# bind = $mainMod Shift, s, exec, <path-to-script>

filename="$HOME/Pictures/Screenshots/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
swappy_filename="$HOME/Pictures/Screenshots/Swappy_$(date +%Y-%m-%d-%H-%M-%S).png"
grimshot savecopy anything "$filename"
if [[ -f $filename ]]; then
    swappy -f "$filename" -o "$swappy_filename"
    if [[ -f $swappy_filename ]]; then
        rm "$filename"
        notify-send "Screenshot saved to clipboard and $swappy_filename"
    else
        notify-send "Screenshot saved to clipboard and $filename"
    fi
else
    notify-send "Screenshot failed"
fi
