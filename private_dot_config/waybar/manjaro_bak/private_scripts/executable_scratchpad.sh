#!/bin/sh

# Function that returns a json-formatted list of scratch nodes
outputScratchNodes() {
    echo $(swaymsg -t get_tree | jq --unbuffered --compact-output '(recurse(.nodes[]) | select(.name == "__i3_scratch") | .focus) as $scratch_ids | [ .. | (.nodes? + .floating_nodes?) // empty | .[] | select(.id|IN($scratch_ids[])) ] as $scratch_nodes | if ($scratch_nodes|length) > 0 then {text: "\($scratch_nodes | length)", tooltip: $scratch_nodes | map("\(.app_id // .window_properties.class) \(.id): \(.name)") | join ("\n")} else empty end')
}

# Output our list when the script is first run
outputScratchNodes

# Subscribe to all sway window change events that match new, move, floating, or close
swaymsg -t subscribe -m '["window"]' | jq -r --unbuffered '.change | IN("new", "move", "floating", "close")| select(. == true)' | \
# Every time we read a line from the previous command ...
while IFS= read -r line
# ... update the indicator
do
    outputScratchNodes
done
