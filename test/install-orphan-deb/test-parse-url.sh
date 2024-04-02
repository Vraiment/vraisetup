#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
test -n "$VRAI_DEBUG" && set -x # Print commands and their arguments as they are executed.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
readonly SCRIPT_DIR

REPOSITORY_ROOT="$(cd -- "$SCRIPT_DIR"/../.. &> /dev/null && pwd)"
readonly REPOSITORY_ROOT

# shellcheck source=libexec/liborphandeb.sh
source "$REPOSITORY_ROOT"/libexec/liborphandeb.sh

function test-url-file-without-version() {
    local config_file

    config_file="$(/usr/bin/mktemp)"
    readonly config_file

    cat << 'EOF' > "$config_file"
URL=https://some-url.com/with/$VERSION/$VERSION.deb
EOF

    test "$(parse-url)" = https://some-url.com/with/\$VERSION/\$VERSION.deb
}

function test-url-file-with-version() {
    local config_file

    config_file="$(/usr/bin/mktemp)"
    readonly config_file

    cat << 'EOF' > "$config_file"
URL=https://some-url.com/with/$VERSION/$VERSION.deb
VERSION=0.0.0
EOF

    test "$(parse-url)" = https://some-url.com/with/0.0.0/0.0.0.deb
}

# shellcheck source=test/run-tests.sh
source "$SCRIPT_DIR"/../run-tests.sh
