#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

function install-extensions() {
    local extension extensions

    extensions=(
        # UI Theme
        akamud.vscode-theme-onedark
        # Icon Theme
        emmanuelbeziat.vscode-great-icons
        # Pretty/Minify JSON
        eriklynd.json-tools
        # URL Encode/Decode
        flesler.url-encode
    )
    readonly extensions

    for extension in "${extensions[@]}"; do
        /snap/bin/code --install-extension "$extension" --force
    done
}

function symlink-configuration() {
    local data_dir
    data_dir="$(readlink -f "$(dirname -- "${BASH_SOURCE[0]}")")"/data
    readonly data_dir

    local vscode_user_dir="$HOME"/.config/Code/User
    readonly vscode_user_dir

    /usr/bin/mkdir --parents "$vscode_user_dir"

    /usr/bin/ln --symbolic --force --backup=numbered \
        "$data_dir"/keybindings.jsonc \
        "$vscode_user_dir"/keybindings.json

    /usr/bin/ln --symbolic --force --backup=numbered \
        "$data_dir"/settings.jsonc \
        "$vscode_user_dir"/settings.json
}

function main() {
    install-extensions
    symlink-configuration
}

main "$@"
