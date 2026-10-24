#!/bin/sh
# vim: filetype=sh

set -eu

log() {
    printf "%0.s*" {1..50}; printf "\n$1\n"; printf "%0.s*" {1..50};echo
}

# syncat is installed by cargo into ~/.cargo/bin, which is only on PATH in new
# shells. The install script put it on its own PATH, not on ours.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

log "Installing tree-sitter languages"

syncat install || {
    status=$?
    printf 'Tree-sitter language installation failed (exit %s).\n' "$status" >&2
    exit "$status"
}

log "Tree-sitter languages installed!"
