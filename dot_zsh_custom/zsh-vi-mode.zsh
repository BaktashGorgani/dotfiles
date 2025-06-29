# Always starting with insert mode for each command line
ZVM_LINE_INIT_MODE=$ZVM_MODE_LAST
ZVM_VI_HIGHLIGHT_FOREGROUND=green             # Color name
ZVM_VI_HIGHLIGHT_FOREGROUND=#008800           # Hex value
ZVM_VI_HIGHLIGHT_BACKGROUND=red               # Color name
ZVM_VI_HIGHLIGHT_BACKGROUND=#ff0000           # Hex value
ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold,underline    # bold and underline

# The plugin will auto execute this zvm_config function
zvm_config() {
  # Retrieve default cursor styles
  local ncur=$(zvm_cursor_style $ZVM_NORMAL_MODE_CURSOR)
  local icur=$(zvm_cursor_style $ZVM_INSERT_MODE_CURSOR)

  # Append your custom color for your cursor
  ZVM_INSERT_MODE_CURSOR=$icur'\e\e]12;red\a'
  ZVM_NORMAL_MODE_CURSOR=$ncur'\e\e]12;#008800\a'
}

# The plugin will auto execute this zvm_after_init function
function zvm_after_init() {
  # Set up fzf key bindings and fuzzy completion
  source <(fzf --zsh)
}
