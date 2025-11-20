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

    # Enable "sudoless" `docker`
    /usr/bin/sudo /usr/sbin/groupadd --force docker
    /usr/bin/sudo /usr/sbin/usermod --append --groups docker "$USER"

    setup-appimages

    "$setup_root"/applications/vscode/install.sh
}

function ensure-sudo() {
    # First remove the timestamp and then ask for the sudo password once
    # this will make it so later calls will have credentials figured out
    /usr/bin/sudo --remove-timestamp
    /usr/bin/sudo /usr/bin/true
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
