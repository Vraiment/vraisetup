#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

function test-something() {
    true
}

function test-something-else() {
    false
}

function not-a-test() {
    echo 'asdf'
}

source $HOME/.local/src/vraisetup/test/run-tests.sh

# mapfile -t defined_functions < <(declare -F)
# defined_functions=($(declare -F | cut --delimiter=' ' --field=3))
# mapfile -t test_functions < <(declare -F  | cut --delimiter=' ' --field=3 | grep '^test-')
# readonly test_functions

# for test_function in "${test_functions[@]}"; do
#     echo "=>Running $test_function"
#     if "$test_function"; then
#         echo succeeded
#     else
#         echo failed
#     fi
# done

# __test_dir=$HOME/.local/src/vraisetup/test/install-orphan-deb
# readonly __test_dir

# source "$__test_dir"/../../libexec/liborphandeb.sh

# function test-url-file-without-version() {
#     local config_file

#     config_file="$(/usr/bin/mktemp)"
#     readonly config_file

#     cat << 'EOF' > "$config_file"
# URL=https://some-url.com/with/$VERSION/$VERSION.deb
# EOF

#     test "$(parse-url)" = https://some-url.com/with/\$VERSION/\$VERSION.deb
# }

# function test-url-file-with-version() {
#     local config_file

#     config_file="$(/usr/bin/mktemp)"
#     readonly config_file

#     cat << 'EOF' > "$config_file"
# URL=https://some-url.com/with/$VERSION/$VERSION.deb
# VERSION=0.0.0
# EOF

#     test "$(parse-url)" = https://some-url.com/with/0.0.0/0.0.0.deb
# }

# function main() {
#     test-url-file-without-version
#     test-url-file-with-version
# }

# main "$@"
