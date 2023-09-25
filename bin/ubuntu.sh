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
    install-orphan-software

    remove-unused-software

    install-gnome-extensions
    install-scripting-runtimes
    install-webapps

    setup-command-line
    setup-gnome-settings
    setup-gnome-terminal-profile
    setup-flatpak-applications
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
    /usr/bin/sudo /usr/bin/apt upgrade --assume-yes
    /usr/bin/sudo /usr/bin/apt autoremove --assume-yes
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
    # Each snap must be installed separately
    # otherwise reruning the command will fail
    /usr/bin/sudo /usr/bin/snap install code --classic
    /usr/bin/sudo /usr/bin/snap install spotify
    /usr/bin/sudo /usr/bin/snap install vlc
}

function install-common-software-flatpak() {
    local software

    software=(
        com.github.PintaProject.Pinta
        com.github.tchx84.Flatseal
        io.missioncenter.MissionCenter
        org.gimp.GIMP
        org.gnome.baobab
        org.gnome.Boxes
        org.gnome.Characters
        org.gnome.Cheese
        org.gnome.clocks
        org.gnome.eog
        org.gnome.Evince
        org.gnome.Extensions
        # org.gnome.FileRoller File Roller is part of the Ubuntu Desktop package
        org.gnome.gitg
        org.gnome.Logs
        org.gnome.Maps
        org.gnome.TextEditor
        org.gnome.Weather
        org.gtk.Gtk3theme.Yaru-Blue-dark/x86_64/3.22 # The default Yaru version installed is 3.22
        org.libreoffice.LibreOffice
        org.mozilla.firefox
    )
    readonly software

    # Install system wide with sudo, this is because I don't want to use home
    # directory storage on flatpak applications
    /usr/bin/sudo /usr/bin/flatpak install --system --assumeyes "${software[@]}"
}

# "Orphan" software in this context referts to applications that are not
# *officially* distributed via `apt`, `flatpak`  or `snap` and need to
# be downloaded and installed manually.
function install-orphan-software() {
    local deb_dir discord_deb naps2_deb simplenote_deb steam_deb

    deb_dir="$data_dir"/deb
    readonly deb_dir

    /usr/bin/mkdir --parents "$deb_dir"

    # Install Discord, sha256sum calculated Sept 17th, 2023
    discord_deb=discord-0.0.29.deb
    readonly discord_deb
    install-orphan-deb \
        https://dl.discordapp.net/apps/linux/0.0.29/"$discord_deb" \
        55f1e92dfa72f6da713b356580b1fefaf9a0b9018d1d1a37b4d3f0b42ad7fffa \
        "$deb_dir"/"$discord_deb"

    # Install NAPS2, sha256sum calculated Sept 17th, 2023
    # NAPS2 it's also offered as a Flatpak but given the USB limitations with Flatpak
    # that version is literally useless.
    naps2_deb=naps2-7.1.0-linux-x64.deb
    readonly naps2_deb
    install-orphan-deb \
        https://github.com/cyanfish/naps2/releases/download/v7.1.0/"$naps2_deb" \
        642ed69cb8ae7d9d89d03451008a014e9b54f341d4dc781718f5317b60bc08cc \
        "$deb_dir"/"$naps2_deb"

    # Install Simplenote, sha256sum calculated Sept 17th, 2023
    simplenote_deb=Simplenote-linux-2.21.0-amd64.deb
    readonly simplenote_deb
    install-orphan-deb \
        https://github.com/Automattic/simplenote-electron/releases/download/v2.21.0/"$simplenote_deb" \
        b3ba6bff0ae5f30d8ef0d7ed60a4f3b95e18fb16856dcbbbb12fcb39122c4aef \
        "$deb_dir"/"$simplenote_deb"

    # Install Steam, sha256sum calculated Sept 17th, 2023
    # Valve publishes the deb to the Steam page as `steam_latest.deb`
    # but the repository is browsable and has links to all of the
    # versions
    steam_deb=steam-launcher_1.0.0.78_all.deb
    readonly steam_deb
    install-orphan-deb \
        https://repo.steampowered.com/steam/archive/precise/"$steam_deb" \
        456c200c00f7cae57db06d2067fbdb1fa3727eb6744371827913c4cf82d507a0 \
        "$deb_dir"/"$steam_deb"
}

function install-orphan-deb() {
    local deb_url deb_sum deb_path package_name package_new_version package_old_version

    deb_url="$1"
    readonly deb_url

    deb_sum="$2"
    readonly deb_sum

    deb_path="$3"
    readonly deb_path

    # Download the deb and check its signature
    /usr/bin/curl --output "$deb_path" --location "$deb_url"
    echo "$deb_sum" "$deb_path" | /usr/bin/sha256sum --check

    package_name="$(/usr/bin/dpkg --field "$deb_path" Package)"
    readonly package_name

    package_new_version="$(/usr/bin/dpkg --field "$deb_path" Version)"
    readonly package_new_version

    package_old_version=$(/usr/bin/dpkg-query --showformat='${Version}' --show "$package_name" || echo '')
    readonly package_old_version

    # An empty "$package_old_version" means the package hasn't been installed
    if [[ -z "$package_old_version" ]] || /usr/bin/dpkg --compare-versions "$package_new_version" gt "$package_old_version"; then
        /usr/bin/sudo /usr/bin/apt install --assume-yes "$deb_path"
    fi
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
        /usr/bin/gnome-extensions install --force "$data_dir"/extensions/"$extension"
    done

    # Enable the extensions by setting the values on gsettings directly rather than via `gnome-extensions`
    # as the later requires a session reboot for it to work
    /usr/bin/gsettings set org.gnome.shell enabled-extensions \
        "['bluetooth-quick-connect@bjarosze.gmail.com', 'gsconnect@andyholmes.github.io', 'weeks-start-on-monday@extensions.gnome-shell.fifi.org']" && sleep 1
}

function install-scripting-runtimes() {
    # sha256sum calculated Sept 23th, 2023
    install-from-github \
        https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh \
        69da4f89f430cd5d6e591c2ccfa2e9e3ad55564ba60f651f00da85e04010c640

    # sha256sum calculated Sept 23th, 2023
    install-from-github \
        https://raw.githubusercontent.com/rbenv/rbenv-installer/33926644327c067be973c8e1c6c4f5c2178d4ead/bin/rbenv-installer \
        e5fe1edc05d827bc87f7ea9724b19632cc68bff10a04912bfd1017385f22f2fb
}

function install-webapps() {
    "$setup_root"/bin/nativefy.sh WhatsApp https://web.whatsapp.com
}

function install-from-github() {
    local url sha256sum install_script

    url="$1"
    readonly url

    sha256sum="$2"
    readonly sha256sum

    install_script="$(mktemp)"
    readonly install_script

    /usr/bin/curl \
        --fail \
        --output "$install_script" \
        --silent \
        --show-error \
        --location "$url"

    if ! echo "$sha256sum" "$install_script" | /usr/bin/sha256sum --check; then
        >&2 echo Validation for "$url" failed
        exit 1
    fi

    # `nvm` suggest setting `PROFILE` to `/dev/null` to prevent the script modifying
    # shell scripts, my guess is this is a general hack and not specific to `nvm`
    PROFILE=/dev/null /usr/bin/bash "$install_script"
}

function setup-command-line() {
    /usr/bin/ln --symbolic --force --backup=numbered "$setup_root"/etc/vimrc "$HOME"/.vimrc

    install-vraishell
}

function install-vraishell() {
    local vraishell_dir

    vraishell_dir="$HOME"/.local/src/vraishell
    readonly vraishell_dir

    if [ ! -d "$vraishell_dir" ]; then
        # Ensure the parents of `$vraishell_dir` exist before cloning
        /usr/bin/mkdir --parents "$(/usr/bin/dirname "$vraishell_dir")"
        /usr/bin/git clone https://github.com/Vraiment/vraishell.git "$vraishell_dir"
    fi

    "$vraishell_dir"/install.sh
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

function setup-flatpak-applications() {
    local flatpaks_with_custom_theme

    # These applications do not match the theme out of the box and need to be manually forced
    # to the closest onet
    flatpaks_with_custom_theme=(
        com.github.PintaProject.Pinta
        org.gnome.Cheese
        org.libreoffice.LibreOffice
        org.mozilla.firefox
    )
    readonly flatpaks_with_custom_theme

    for flatpak_with_custom_theme in "${flatpaks_with_custom_theme[@]}"; do
        /usr/bin/flatpak override --user --env=GTK_THEME=Yaru-Blue-dark "$flatpak_with_custom_theme"
    done
}

main "$@"
