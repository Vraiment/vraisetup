#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

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
