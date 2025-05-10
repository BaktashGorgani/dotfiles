if [[ -n "$TMUX" ]]; then
    export FZF_DEFAULT_OPTS="
        --cycle
        --border
    "
fi

fjs_change_entry() {
    local ipRegex="^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$"
    local jumpServer="$1"
    local entryArray=(
        $(
            cat "$HOME/.connections/$jumpServer" |
            fzf --ansi --prompt="Change entry: " \
                --bind="esc:become($HOME/.connections/scripts/fjs_menu.bash)"
        )
    )
    if [[ -z "${entryArray[@]}" ]]; then
        echo "No entry selected"
        return 1
    fi
    local name=${entryArray[0]}
    local ip=${entryArray[1]}
    echo "Current entry: $name($ip)"
    echo "Enter new name (press enter to leave unchanged):"
    read newName
    if [[ -z "$newName" ]]; then
        newName=$name
    fi
    while [[ -z "$newIp" ]]; do
        echo "Enter new IP (press enter to leave unchanged):"
        read newIp
        if [[ -z "$newIp" ]]; then
            newIp=$ip
        elif [[ ! $newIp =~ $ipRegex ]]; then
            echo "$newIp is not a valid IP. Please try again"
            newIp=""
        fi
    done
    if [[ "$newName" == "$name" && "$newIp" == "$ip" ]]; then
        echo "No changes made"
    else
        sed -i "s/$name $ip/$newName $newIp/" "$HOME/.connections/$jumpServer"
        echo "Entry changed to $newName($newIp)"
    fi
}

fjs_change_entry "$1"
if  [[ $? -ne 0 ]]; then
    exit 1
else
    exit 0
fi
