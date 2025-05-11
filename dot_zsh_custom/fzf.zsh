export FZF_DEFAULT_OPTS="
    --tmux 97%
    --walker-skip .steam,.git,node_modules,target,.cache,.gradle,venv,.cache,sys,proc,.file,.npm,.dartserver,.mypy_cache,HedgeModManager,dosdevices
    --cycle
    --border
"
export FZF_ALT_C_OPTS="
    $FZF_DEFAULT_OPTS
    --preview 'tree -C {}'
"

 # Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
