#!/bin/bash

scrollback_file=$(mktemp)
tmux capture-pane -JpS - > "$scrollback_file"
nvim '+call delete(@%)' "$scrollback_file"
