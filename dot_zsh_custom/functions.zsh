is_git_repo () {
  return $(git rev-parse --is-inside-work-tree &>/dev/null)
}

frg () {
    rm -f /tmp/rg-fzf-{r,f}
    RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
    INITIAL_QUERY="${*:-}"
    fzf --ansi --disabled --query "$INITIAL_QUERY" \
        --bind "start:reload:$RG_PREFIX {q}" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind 'ctrl-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
          echo "rebind(change)+change-prompt(1. ripgrep> )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
          echo "unbind(change)+change-prompt(2. fzf> )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --prompt '1. ripgrep> ' \
        --delimiter : \
        --header 'CTRL-T: Switch between ripgrep/fzf' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(nvim {1} +{2})'
}
fgc () {
  if ! is_git_repo; then
    echo "Not a git repository"
    return 1
  fi

    git checkout \
        $(
            (
                git branch -a -vv --color=always;
                pgl;
            ) |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | awk '{print \$1}')" |
            awk '{print $1}' |
            sed 's/\*//'
        )
}
fgbc () {
  if ! is_git_repo; then
    echo "Not a git repository"
    return 1
  fi

    git checkout \
        $(
            git branch -a -vv --color=always |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | awk '{print \$1}')" |
            awk '{print $1}' |
            sed 's/\*//'
        )
}
fgcc () {
  if ! is_git_repo; then
    echo "Not a git repository"
    return 1
  fi

    git checkout \
        $(
            pggl |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | sed -E 's/[^a-f0-9]*([a-f0-9]+).*/\1/')" |
            sed -E 's/[^a-f0-9]*([a-f0-9]+).*/\1/'
        )
}

screenshot () {
    local filename="$HOME/Pictures/Screenshots/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
    grimshot savecopy anything "$filename"
    notify-send "Screenshot saved to clipboard and $filename"
}

swap_sway_wksp () {
    local wksp=$(swaymsg -rt get_workspaces | jq -r '.[] | select(.focused == true).num')
    local query="string join '' '.. | select(.type?) | select(.num == ' $1 ') | .output'"
    local output=$(swaymsg -rt get_outputs | jq -r $query)

    swaymsg [workspace = $1] move workspace to output current
    swaymsg [workspace = $wksp] move workspace to output $output
    swaymsg workspace number $1
}

get_file () {
    if [[ ! -d "$HOME/remote_device_files" ]]; then
        mkdir -p $HOME/remote_device_files
    fi

    if [[ "$1" != "sftp" && "$1" != "scp" ]]; then
            echo "Only scp and sftp are supported. Please use one of these as the first argument to this function"
            return 1
    fi

    "$1" $REMOTEUSER@"$2":"$3" "$HOME"/remote_device_files/

}

performance () {
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

scrollback() {
  scrollback_file=$(mktemp)
  tmux capture-pane -pS - > "$scrollback_file"
  nvim '+call delete(@%)' "$scrollback_file"
}
