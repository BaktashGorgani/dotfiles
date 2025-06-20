alias profile='exec zsh'
alias zshrc='nvim ~/.zshrc'
alias zsh-custom='nvim ~/.zsh_custom'
alias origin='git push origin main'
alias live='git push live main'
alias activate='source ./venv/bin/activate'
alias arrislc='cd ~/git/arris-lc-failover && activate'
alias nvim-config='cd ~/.config/nvim && nvim .'
alias tmux-config='nvim ~/.tmux.conf'
alias tm='tmux new -A -s Main'
alias tkill='tmux kill-server'
alias tsave='~/tmux-session save'
alias trestore='~/tmux-session restore && tmux a'
alias nv='nvim .'
alias bat='bat --color=always'
alias fz='fzf -m --preview "bat --show-all --color=always --line-range=:500 {}"'
alias fnv='fz --bind "enter:become(nvim {+}),ctrl-v:become(nvim -O {+})" --header "Press Ctrl-V to open in vertical split"'
alias fcd='`__fzf_cd__`'
alias fb='fz --bind "enter:become(bat {})"'
alias pgl="git log --color=always --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
alias pggl="pgl --graph"
alias disks="gdu -d"


# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r $HOME/.dircolors && eval "$(dircolors -b $HOME/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'

# eza
alias ez='eza -al --total-size --icons=always --color=always --group-directories-first --git --git-repos --time-style="+%b %d %Y %l:%M %p"'
alias ezt='ez -T'

# load new wallpapers
alias wallpaper='$HOME/git/bing_wallpaper/bing_wallpaper_optimized'

# lazygit
alias lg='lazygit'

# chezmoi update and refresh
alias cur='chezmoi update --refresh-externals'
