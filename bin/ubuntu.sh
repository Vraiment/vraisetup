#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

function main() {
    ensure-sudo

    install-common-software-apt
    install-common-software-snap
    add-flathub
    install-common-software-flatpak

    # The Snap store is not great, and the Gnome Software application
    # supports deb, snap and flatpak. So instead that gets installed
    # and this one removed
    remove-snap-store
}

function ensure-sudo() {
    /bin/sudo --reset-timestamp /bin/true
}

function install-common-software-apt() {
    local software

    software=(
        curl
        flatpak
        git
        gnome-software
        gnome-software-plugin-flatpak
        gnome-software-plugin-snap
        gnome-sushi # Preview files from Nautilus
        gnome-tweaks
        hunspell-es # Spanish dictionary
        shellcheck
        vim
        wl-clipboard # Copy&paste in the terminal
    )
    readonly software

    sudo apt update
    sudo apt install --assume-yes "${software[@]}"
}

function install-common-software-snap() {
    sudo snap install code --classic
    sudo snap install spotify
}

function install-common-software-flatpak() {
    local software

    software=(
        com.github.tchx84.Flatseal
        io.missioncenter.MissionCenter
        org.gimp.GIMP
        org.gnome.Boxes
        org.gnome.Cheese
        org.gnome.Evince
        org.gnome.gitg
        org.libreoffice.LibreOffice
    )
    readonly software

    # Install system wide with sudo, this is because I don't want to use home
    # directory storage on flatpak applications
    sudo flatpak install --system --assumeyes "${software[@]}"
}

function add-flathub() {
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function remove-snap-store() {
    sudo snap remove --purge snap-store
}

main "$@"
