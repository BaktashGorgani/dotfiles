if [[ -n "$TMUX" ]]; then
    export FZF_DEFAULT_OPTS="
        --cycle
        --border
    "
fi

fjs_delete_entry () {
    local jumpServer="$1"
    local entryArray=(
        $(
            cat "$HOME/.connections/$jumpServer" |
            fzf --ansi --prompt="Delete entry: " \
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
    echo "Are you sure you want to delete this entry?"
    select ync in "Yes" "No"; do
        case $ync in
            Yes ) sed -i "/$name $ip/d" "$HOME/.connections/$jumpServer"; echo "Entry deleted"; break;;
            No ) echo "Entry left alone"; break;;
            * ) echo "Please answer 1 for Yes or 2 for No";;
        esac
    done
}

fjs_delete_entry "$1"
