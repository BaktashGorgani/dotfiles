export FZF_DEFAULT_OPTS="
    --walker-skip .steam,.git,node_modules,target,.cache,.gradle,venv,.cache,sys,proc,.file,.npm,.dartserver,.mypy_cache,HedgeModManager,dosdevices,Android
    --cycle
    --border
    --bind ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up
    --bind ctrl-e:preview-down,ctrl-y:preview-up
"
export FZF_ALT_C_OPTS="
    $FZF_DEFAULT_OPTS
    --preview 'eza -T --color=always --icons=always {}'
"

 # Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
