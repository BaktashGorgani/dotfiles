#!/bin/bash

scrollback_file=$(mktemp)
tmux capture-pane -pS - > "$scrollback_file"
nvim '+call delete(@%)' "$scrollback_file"
