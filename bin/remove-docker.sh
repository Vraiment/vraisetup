#!/bin/bash

# Exit on any error
set -o errexit

# Fail on any undefined variable
set -o nounset

# Propagate errors through pipes
set -o pipefail

# Print trace for debugging
set -o xtrace

shellcheck "${BASH_SOURCE[0]}"

function main() {
    local -r packagesFile=/var/lib/apt/lists/download.docker.com_linux_ubuntu_dists_noble_stable_binary-amd64_Packages
    local -a packages
    while IFS='' read -r line; do packages+=("$line"); done < <(grep '^Package: ' "$packagesFile" | sort --unique | cut --delimiter ' ' --field 2)

    /usr/bin/sudo /usr/bin/apt autopurge "${packages[@]}"

    # Delete repository related packages
    /usr/bin/sudo /usr/bin/rm --force /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc
    /usr/bin/sudo /usr/bin/apt update

    # Remove group related changes
    /usr/bin/sudo /usr/bin/gpasswd --delete "$USER" docker
    /usr/bin/sudo /usr/sbin/groupdel docker
}

main "$@"
