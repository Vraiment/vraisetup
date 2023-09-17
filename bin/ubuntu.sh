#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

# Setup root is defined as the absolute path (`readlink`) of the
# parent of the directory (`dirname`) of the current script (`${BASH_SOURCE[0]}`)
setup_root="$(readlink -f "$(dirname -- "${BASH_SOURCE[0]}")"/..)"
readonly setup_root

data_dir="$HOME"/.local/share/vraisetup/data
readonly data_dir

function main() {
    ensure-sudo

    /usr/bin/mkdir --parents "$data_dir"

    install-common-software-apt
    install-common-software-snap
    add-flathub
    install-common-software-flatpak

    remove-unused-software

    install-gnome-extensions
    setup-gnome-settings
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

    configure-extra-apt-repositories

    software=(
        1password
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
        signal-desktop
        vim
        wl-clipboard # Copy&paste in the terminal
    )
    readonly software

    /usr/bin/sudo /usr/bin/apt update
    /usr/bin/sudo /usr/bin/apt install --assume-yes "${software[@]}"
}

function configure-extra-apt-repositories() {
    # Use --no-preserve=mode,ownership,timestmap to ensure the
    # permissions of the files are root's and not the current user

    # First configure Signal, see the README on the Signal dir
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/signal/signal-desktop-keyring.gpg \
        /usr/share/keyrings/signal-desktop-keyring.gpg
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/signal/signal-xenial.list \
        /etc/apt/sources.list.d/signal-xenial.list

    # Configure 1Password, see the README on the 1Password dir
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/1password/1password-archive-keyring.gpg \
        /usr/share/keyrings/1password-archive-keyring.gpg
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/1password/1password.list \
        /etc/apt/sources.list.d/1password.list
    # Configure debsig-verify policy for 1Password
    /usr/bin/sudo /usr/bin/mkdir --parents /etc/debsig/policies/AC2D62742012EA22
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/1password/1password.pol \
        /etc/debsig/policies/AC2D62742012EA22/1password.pol
    /usr/bin/sudo /usr/bin/mkdir --parents /usr/share/debsig/keyrings/AC2D62742012EA22
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/1password/1password-archive-keyring.gpg \
        /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
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
        org.gnome.baobab
        org.gnome.Boxes
        org.gnome.Characters
        org.gnome.Cheese
        org.gnome.eog
        org.gnome.Evince
        org.gnome.Extensions
        # org.gnome.FileRoller File Roller is part of the Ubuntu Desktop package
        org.gnome.gitg
        org.gnome.Logs
        org.gnome.TextEditor
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
    local apt_packages

    # The Snap store is not great, and the Gnome Software application
    # supports deb, snap and flatpak. So instead that gets installed
    # and this one removed
    /usr/bin/sudo /usr/bin/snap remove --purge snap-store

    # At this point I think using Firefox from Flatpak (previously
    # installed) will be better from Snap as the settings are more
    # accessible from Flatseal
    /usr/bin/sudo /usr/bin/snap remove --purge firefox

    # For this software the flatpak version is installed instead
    apt_packages=(
        evince
        eog
        # file-roller File Roller is considered part of the Ubuntu Desktop
        gedit
        gnome-characters
        gnome-logs
    )
    readonly apt_packages

    /usr/bin/sudo /usr/bin/apt autoremove --purge --assume-yes "${apt_packages[@]}"
}

function install-gnome-extensions() {
    # All this installation omits the `gnome-extensions` command as it requires
    # the gnome session running restarted to work
    local extensions extension extension_dir

    # These versions were manually selected from the UI to match the Gnome version in Ubuntu 22.04
    # hence they are hardcoded, they can be updated from the UI or via this script by changing 
    # the values
    extensions=(
        gsconnectandyholmes.github.io.v50.shell-extension.zip
        bluetooth-quick-connectbjarosze.gmail.com.v34.shell-extension.zip
        weeks-start-on-mondayextensions.gnome-shell.fifi.org.v13.shell-extension.zip
    )
    readonly extensions

    extension_dir="$HOME"/.local/share/gnome-shell/extensions
    readonly extension_dir

    # Downloaded extensions get stored in the setup data dir
    /usr/bin/mkdir --parents "$data_dir"/extensions "$extension_dir"

    for extension in "${extensions[@]}"; do
        /usr/bin/curl --output-dir "$data_dir"/extensions --remote-name https://extensions.gnome.org/extension-data/"$extension"
        /usr/bin/gnome-extensions install "$data_dir"/extensions/"$extension"
    done

    # Enable the extensions by setting the values on gsettings directly rather than via `gnome-extensions`
    # as the later requires a session reboot for it to work
    /usr/bin/gsettings set org.gnome.shell enabled-extensions \
        "['bluetooth-quick-connect@bjarosze.gmail.com', 'gsconnect@andyholmes.github.io', 'weeks-start-on-monday@extensions.gnome-shell.fifi.org']" && sleep 1
}

function setup-gnome-settings() {
    # These seem to be exclusive to Ubuntu (maybe even Ubuntu 22.04)
    # Wait for 1 second after each invocation as there is a slight delay before the settings
    # get applied, otherwise the ones after the first one won't get applied

    # Reset the layout of the app grid
    /usr/bin/gsettings reset org.gnome.shell app-picker-layout && sleep 1

    # Set dark theme
    /usr/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface gtk-theme Yaru-blue-dark && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface icon-theme Yaru-blue && sleep 1

    # Enable hot corners
    /usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners true && sleep 1

    # Configure dock: auto hide, show at bottom, do not fill the screen
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false && sleep 1
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM && sleep 1
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false && sleep 1

    # Configure desktop icons
    /usr/bin/gsettings set org.gnome.shell.extensions.ding start-corner top-left && sleep 1

    # Compose key allows to write tildes and the like
    /usr/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['compose:rctrl']" && sleep 1

    # Keyboard shortcuts
    /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>f']" && sleep 1
    /usr/bin/gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']" && sleep 1
}

function setup-gnome-terminal-profile() {
    /usr/bin/dconf load /org/gnome/terminal/legacy/profiles:/ < "$setup_root"/etc/VraiTerminal.dconf
}

main "$@"
