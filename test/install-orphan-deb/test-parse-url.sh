#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
test -n "$VRAI_DEBUG" && set -x # Print commands and their arguments as they are executed.

TEST_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
readonly TEST_SCRIPT_DIR

# shellcheck source=libexec/liborphandeb.sh
source "$TEST_SCRIPT_DIR"/../../libexec/liborphandeb.sh

function test-url-file-without-version() {
    local config_file

    config_file="$(/usr/bin/mktemp)"
    readonly config_file

    cat << 'EOF' > "$config_file"
URL=https://some-url.com/with/$VERSION/$VERSION.deb
EOF

    trap "rm $config_file" EXIT
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

    trap "rm $config_file" EXIT
    test "$(parse-url)" = https://some-url.com/with/0.0.0/0.0.0.deb
}
