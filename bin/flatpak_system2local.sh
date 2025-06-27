#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

readonly CUT=/usr/bin/cut
readonly FLATPAK=/usr/bin/flatpak
readonly GREP=/usr/bin/grep
readonly SED=/usr/bin/sed
readonly SUDO=/usr/bin/sudo

function main() {
    local allApps app allRuntimes runtime

    "$FLATPAK" remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
     # Default separator for `cut` is `\t`
    allApps=$("$FLATPAK" list --system --app --columns=origin,application,branch | ("$GREP" '^flathub' || true) | "$CUT" --fields=2,3 | "$SED" "s|\t|/x86_64/|g")
    readonly allApps

    for app in $allApps; do
        "$FLATPAK" install --or-update --user --assumeyes "$app"
        "$SUDO" "$FLATPAK" uninstall --system --assumeyes "$app"
    done

    allRuntimes=$("$FLATPAK" list --system --runtime --columns=origin,application,branch | ("$GREP" '^flathub' || true) | "$CUT" --fields=2,3 | "$SED" "s|\t|/x86_64/|g")
    readonly allRuntimes

    for runtime in $allRuntimes; do
        "$SUDO" "$FLATPAK" uninstall --system --assumeyes "$runtime" || true
    done

    "$SUDO" "$FLATPAK" remote-delete --system flathub
}

main
