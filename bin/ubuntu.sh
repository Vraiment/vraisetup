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

    install-orphan-software

    install-scripting-runtimes

    # Enable "sudoless" `docker`
    /usr/bin/sudo /usr/sbin/groupadd --force docker
    /usr/bin/sudo /usr/sbin/usermod --append --groups docker "$USER"

    # Set firefox as default browser
    /usr/bin/xdg-settings set default-web-browser com.brave.Browser.desktop

    setup-command-line
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

# "Orphan" software in this context referts to applications that are not
# *officially* distributed via `apt`, `flatpak`  or `snap` and need to
# be downloaded and installed manually.
function install-orphan-software() {
    local deb_dir simplenote_version simplenote_deb steam_deb

    deb_dir="$data_dir"/deb
    readonly deb_dir

    /usr/bin/mkdir --parents "$deb_dir"

    # Install NAPS2, sha256sum calculated Sep 01st, 2025
    # NAPS2 it's also offered as a Flatpak but given the USB limitations with Flatpak
    # that version is literally useless.
    naps2_version=8.2.1
    readonly naps2_version
    install-orphan-deb \
        https://github.com/cyanfish/naps2/releases/download/v"$naps2_version"/naps2-"$naps2_version"-linux-x64.deb \
        8e23c4a6d7f0b75512459cc29a639ec395355f222375291ed674525c7c9cd4b7 \
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

function setup-flatpak-applications() {
    local flatpak_with_custom_theme flatpaks_with_custom_theme

    # These applications do not match the theme out of the box and need to be manually forced
    # to the closest onet
    flatpaks_with_custom_theme=(
        org.libreoffice.LibreOffice
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
