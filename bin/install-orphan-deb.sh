#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

function main1() {
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

function parse-url() {
    local version_field url_field

    version_field="$(/usr/bin/grep '^VERSION=' "$config_file" | /usr/bin/cut --delimiter='=' --fields=2-)"
    readonly version_field

    url_field="$(/usr/bin/grep '^URL=' "$config_file" | /usr/bin/cut --delimiter='=' --fields=2-)"
    readonly url_field

    if [ -n "$version_field" ]; then
        echo "$url_field" | /usr/bin/sed s/\$VERSION/"$version_field"/g
    else
        echo "$url_field"
    fi
}

function main() {
    local config_file url sha256sum deb_path

    config_file="$1"
    readonly config_file

    url="$(parse-url)"
    readonly url

    sha256sum="$(parse-sha256)"
    readonly sha256sum

    ensure-deb-downloaded

    if package-needs-install; then
        /usr/bin/sudo /usr/bin/apt install --assume-yes "$(deb-path)"
    fi
}

# Run main only if the script is not sourced
if ! (return 0 2> /dev/null); then
    main "$@"
fi
