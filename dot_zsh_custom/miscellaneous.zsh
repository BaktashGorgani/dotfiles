# Copilot functions
#eval "$(gh copilot alias -- zsh)"

# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
autoload -Uz compinit
compinit

# Oh My Posh
eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/night-owl.omp.json)"

# chezmoi completion
eval "$(chezmoi completion zsh)"

# enable zoxide
eval "$(zoxide init --cmd cd zsh)"
eval "$(zoxide init zsh)"
