# Copilot functions
eval "$(gh copilot alias -- zsh)"

# Oh My Posh
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/night-owl.omp.json)"

# chezmoi completion
eval "$(chezmoi completion zsh)"
