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

    remove-unused-software

    setup-gnome-terminal-profile
}

function ensure-sudo() {
    # First remove the timestamp and then ask for the sudo password once
    # this will make it so later calls will have credentials figured out
    /usr/bin/sudo --remove-timestamp
    /usr/bin/sudo /usr/bin/true
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

    /usr/bin/sudo /usr/bin/apt update
    /usr/bin/sudo /usr/bin/apt install --assume-yes "${software[@]}"
}

function install-common-software-snap() {
    /usr/bin/sudo /usr/bin/snap install code --classic
    /usr/bin/sudo /usr/bin/snap install spotify
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
        org.mozilla.firefox
    )
    readonly software

    # Install system wide with sudo, this is because I don't want to use home
    # directory storage on flatpak applications
    /usr/bin/sudo /usr/bin/flatpak install --system --assumeyes "${software[@]}"
}

function add-flathub() {
    /usr/bin/sudo /usr/bin/flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function remove-unused-software() {
    # The Snap store is not great, and the Gnome Software application
    # supports deb, snap and flatpak. So instead that gets installed
    # and this one removed
    /usr/bin/sudo /usr/bin/snap remove --purge snap-store

    # At this point I think using Firefox from Flatpak (previously
    # installed) will be better from Snap as the settings are more
    # accessible from Flatseal
    /usr/bin/sudo /usr/bin/snap remove --purge firefox

    # For this software the flatpak version is installed instead
    /usr/bin/sudo /usr/bin/apt autoremove --purge --assume-yes evince
}

function setup-gnome-terminal-profile() {
    /usr/bin/dconf load /org/gnome/terminal/legacy/profiles:/ < "$(dirname -- "${BASH_SOURCE[0]}")"/../etc/VraiTerminal.dconf
}

main "$@"
