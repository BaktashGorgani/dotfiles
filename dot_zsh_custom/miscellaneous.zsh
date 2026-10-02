# Copilot functions
#eval "$(gh copilot alias -- zsh)"

# Homebrew (Apple Silicon, Intel macOS or Linuxbrew). oh-my-zsh has already run
# compinit by the time this file is sourced, so it is not repeated here.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x $brew_bin ]]; then
        eval "$($brew_bin shellenv)"
        break
    fi
done
unset brew_bin

# Oh My Posh ($HOMEBREW_PREFIX/opt/<formula> avoids a slow `brew --prefix` call)
eval "$(oh-my-posh init zsh --config "$HOMEBREW_PREFIX/opt/oh-my-posh/themes/night-owl.omp.json")"

# chezmoi completion
eval "$(chezmoi completion zsh)"

# enable zoxide
eval "$(zoxide init --cmd cd zsh)"
eval "$(zoxide init zsh)"
