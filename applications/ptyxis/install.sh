#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

function dataDir() {
    echo "$(readlink -f "$(dirname -- "${BASH_SOURCE[0]}")")"/data
}

function printDataHome() {
    # No need to create the directory, this individual invocation will create it
    # shellcheck disable=SC2016
    flatpak run --command=sh app.devsuite.Ptyxis -c 'echo "$XDG_DATA_HOME"'
}

function installPalette() {
    # Retrieve the location for the data home
    local dataHome
    dataHome="$(printDataHome)"
    readonly dataHome

    local -r palettesDir="$dataHome"/app.devsuite.Ptyxis/palettes

    /usr/bin/mkdir --parents "$palettesDir"
    /usr/bin/ln --symbolic --force --backup=numbered "$(dataDir)"/VraiTerminal.palette "$palettesDir"
}

function main() {
    installPalette
}

main "$@"
