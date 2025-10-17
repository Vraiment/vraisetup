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
