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
    setup-flatpak
    install-common-software-flatpak
    install-orphan-software

    remove-unused-software

    install-gnome-extensions
    install-scripting-runtimes

    # Enable "sudoless" `docker`
    /usr/bin/sudo /usr/sbin/groupadd --force docker
    /usr/bin/sudo /usr/sbin/usermod --append --groups docker "$USER"

    # Set firefox as default browser
    /usr/bin/xdg-settings set default-web-browser org.mozilla.firefox.desktop

    setup-command-line
    setup-gnome-settings
    setup-gnome-terminal-profile
    setup-flatpak-applications

    setup-appimages

    "$setup_root"/applications/vscode/install.sh
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
        containerd.io # Required for Docker
        curl
        docker-buildx-plugin
        docker-ce
        docker-ce-cli
        docker-compose-plugin
        flatpak
        git
        gnome-software
        gnome-software-plugin-flatpak
        gnome-software-plugin-snap
        gnome-sushi # Preview files from Nautilus
        gnome-tweaks
        hunspell-es # Spanish dictionary
        libfuse2 # Required for AppImages
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

    # Configure Docker, see the README on the docker dir
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/docker/docker.list \
        /etc/apt/sources.list.d/docker.list
    /usr/bin/sudo /usr/bin/cp --no-preserve=mode,ownership,timestamp \
        "$setup_root"/etc/docker/docker.asc \
        /etc/apt/keyrings/docker.asc
}

function install-common-software-snap() {
    # Each snap must be installed separately
    # otherwise reruning the command will fail
    /usr/bin/sudo /usr/bin/snap install code --classic
    /usr/bin/sudo /usr/bin/snap install spotify
    /usr/bin/sudo /usr/bin/snap install todoist
    /usr/bin/sudo /usr/bin/snap install vlc
}

function install-common-software-flatpak() {
    local software

    software=(
        com.discordapp.Discord
        com.github.finefindus.eyedropper
        com.github.PintaProject.Pinta
        com.github.tchx84.Flatseal
        io.missioncenter.MissionCenter
        org.gimp.GIMP
        org.gnome.baobab
        org.gnome.Boxes
        org.gnome.Calculator
        org.gnome.Calendar
        org.gnome.Characters
        org.gnome.clocks
        org.gnome.Contacts
        org.gnome.Evince
        org.gnome.Extensions
        org.gnome.font-viewer
        org.gnome.Logs
        org.gnome.Loupe
        org.gnome.Maps
        org.gnome.Snapshot
        org.gnome.TextEditor
        org.gnome.Weather
        org.gtk.Gtk3theme.Yaru-Blue-dark/x86_64/3.22 # The default Yaru version installed is 3.22
        org.libreoffice.LibreOffice
        org.mozilla.firefox
        org.mozilla.Thunderbird
    )
    readonly software

    # Install system wide with sudo, this is because I don't want to use home
    # directory storage on flatpak applications
    /usr/bin/flatpak install --user --assumeyes "${software[@]}"
}

# "Orphan" software in this context referts to applications that are not
# *officially* distributed via `apt`, `flatpak`  or `snap` and need to
# be downloaded and installed manually.
function install-orphan-software() {
    local deb_dir simplenote_version simplenote_deb steam_deb

    deb_dir="$data_dir"/deb
    readonly deb_dir

    /usr/bin/mkdir --parents "$deb_dir"

    # Install NAPS2, sha256sum calculated Jul 10th, 2025
    # NAPS2 it's also offered as a Flatpak but given the USB limitations with Flatpak
    # that version is literally useless.
    naps2_version=8.2.0
    readonly naps2_version
    install-orphan-deb \
        https://github.com/cyanfish/naps2/releases/download/v"$naps2_version"/naps2-"$naps2_version"-linux-x64.deb \
        56e12ef301f870e79cf798b63e6dda9ac58d97b0b465cf420f891b36d481db54 \
        "$deb_dir"/naps2-"$naps2_version"-linux-x64.deb

    # Install Simplenote, sha256sum calculated Jun 02nd, 2025
    simplenote_version=2.23.2
    simplenote_deb=Simplenote-linux-"$simplenote_version"-amd64.deb
    readonly simplenote_version
    install-orphan-deb \
        https://github.com/Automattic/simplenote-electron/releases/download/v"$simplenote_version"/"$simplenote_deb" \
        ae5c5a46347d68031324633c27f33afdeabfc6ffca5f58dd638002e6db99f22b \
        "$deb_dir"/"$simplenote_deb"

    # Install Steam, sha256sum calculated Sept 2nd, 2024
    # Valve publishes the deb to the Steam page as `steam_latest.deb`
    # but the repository is browsable and has links to all of the
    # versions
    steam_deb=steam-launcher_1.0.0.81_all.deb
    readonly steam_deb
    install-orphan-deb \
        https://repo.steampowered.com/steam/archive/stable/"$steam_deb" \
        afd2b922f9771a9ca7ee0cb416bdd4fceabf3e75a2c5b65f654a10419762960d \
        "$deb_dir"/"$steam_deb"
}

function install-orphan-deb() {
    local deb_url deb_sum deb_path tmp package_name package_new_version package_old_version

    deb_url="$1"
    readonly deb_url

    deb_sum="$2"
    readonly deb_sum

    deb_path="$3"
    readonly deb_path

    # If "$deb_path" already exists, warranty it has a valid signature,
    # otherwise back it up for future inspection and remove it.
    if [ -e "$deb_path" ]; then
        if ! echo "$deb_sum" "$deb_path" | /usr/bin/sha256sum --check; then
            >&2 echo Suspicious deb "$deb_path", will back it up

            # Convoluted way of moving `"$deb_path"` "into itself" so we can
            # leverage `mv --backup` for backing it up.
            # 1. Create a temporary file
            # 2. Move the temporary file into the file we
            #    want to backup
            # 3. Delete the temporary file
            tmp="$(mktemp)"
            readonly tmp

            /usr/bin/mv --backup=numbered "$tmp" "$deb_path"
            /usr/bin/rm "$deb_path"
        fi
    fi

    # If the deb didn't already exist with a valid signature, download it.
    if [ ! -e "$deb_path" ]; then
        /usr/bin/curl --output "$deb_path" --location "$deb_url"
        echo "$deb_sum" "$deb_path" | /usr/bin/sha256sum --check
    fi

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

function setup-flatpak() {
    # Add required AppArmor profile for Flatpaks
    # ref: https://bugs.launchpad.net/ubuntu/+source/gnome-software/+bug/2061728/comments/5
    /usr/bin/cat << EOF | /usr/bin/sudo /usr/bin/tee /etc/apparmor.d/bwrap
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/bwrap>
}
EOF
    /usr/bin/sudo /usr/bin/systemctl reload apparmor

    # Add FlatHub, which is the central FlatPak repository
    /usr/bin/flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Add (mexican) spanish as a secondary language (for spellchecking)
    /usr/bin/sudo /usr/bin/flatpak config --set extra-languages es_MX
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
        baobab
        eog
        evince
        gedit
        gnome-calculator
        gnome-characters
        gnome-clocks
        gnome-font-viewer
        gnome-logs
        gnome-power-manager
        gnome-snapshot
        gnome-text-editor
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
        "['gsconnect@andyholmes.github.io', 'weeks-start-on-monday@extensions.gnome-shell.fifi.org']" && sleep 1
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

    # Setup clock
    /usr/bin/gsettings set org.gnome.desktop.interface clock-format 24h && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface clock-show-date true && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface clock-show-weekday true && sleep 1

    # Set weather units
    /usr/bin/gsettings set org.gnome.GWeather4 temperature-unit centigrade && sleep 1

    # Do not attach mini windows to their parents
    /usr/bin/gsettings set org.gnome.mutter attach-modal-dialogs false && sleep 1

    # Set dark theme
    /usr/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface gtk-theme Yaru-blue-dark && sleep 1
    /usr/bin/gsettings set org.gnome.desktop.interface icon-theme Yaru-blue && sleep 1

    # Enable hot corners
    /usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners true && sleep 1

    # Disable the third mouse button behaving like ctrl+v
    /usr/bin/gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false && sleep 1

    # Open new instances of the app when clicking the dock
    /usr/bin/gsettings set org.gnome.shell.app-switcher current-workspace-only false && sleep 1

    # Configure dock: auto hide, show at bottom, do not fill the screen
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false && sleep 1
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM && sleep 1
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false && sleep 1
    # Hide not mounted disks (mounted disks will still show up)
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted true && sleep 1
    # Show on all screens
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true && sleep 1
    # Show the apps icons at the beginning of the dock, not at the end
    /usr/bin/gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true && sleep 1

    # Configure desktop icons
    /usr/bin/gsettings set org.gnome.shell.extensions.ding start-corner top-left && sleep 1

    # Ensure trackpads use the whole trackpad as trackpad and only two fingers as a secondary click
    /usr/bin/gsettings set org.gnome.desktop.peripherals.touchpad click-method fingers && sleep 1

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
    local flatpak_with_custom_theme flatpaks_with_custom_theme

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

    # Ensure weeks start on MOnday for Gnome calendar, en_DK should be identical
    # with the exception of the start of the week
    /usr/bin/flatpak override --user --env=LC_TIME=en_DK.UTF-8 org.gnome.Calendar
}

function setup-appimages() {
    # Allows AppImages to be placed under `$HOME/Applications/*.AppImage`
    /usr/bin/cat << EOF | /usr/bin/sudo /usr/bin/tee /etc/apparmor.d/userappimages
abi <abi/4.0>,
include <tunables/global>

profile userappimages @{HOME}/Applications/*.AppImage flags=(default_allow) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/userappimages>
}
EOF
    /usr/bin/sudo /usr/bin/systemctl reload apparmor

    # TODO: Add `appimaged`
}

main "$@"
