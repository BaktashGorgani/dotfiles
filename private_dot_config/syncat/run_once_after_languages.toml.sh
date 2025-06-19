#!/bin/sh
# vim: filetype=sh
function log() {
    printf "%0.s*" {1..50}; printf "\n$1\n"; printf "%0.s*" {1..50};echo
}

log "Installing tree-sitter languages"

syncat install

log "Tree-sitter languages installed!"
