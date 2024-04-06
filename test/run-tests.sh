#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
test -n "$VRAI_DEBUG" && set -x # Print commands and their arguments as they are executed.

function on-a-separate-bash() {
    local -r function_name="$1"
    shift

    local var variables_to_forward
    variables_to_forward=''
    for var in "$@"; do
        variables_to_forward+="$var=${!var} "
    done

    "$BASH" -c "$(declare -f "$function_name"); $variables_to_forward $function_name"
}

function read-tests() {
    # shellcheck disable=SC1090
    source "$test_file"

    declare -F | cut --delimiter=' ' --field=3 | grep '^test-'
}

function run-single-test() {
    echo -e "\033[0;33mRunning test $test_to_run...\033[0m"

    # shellcheck disable=SC1090
    source "$test_file"

    if "$test_to_run"; then
        echo -e "\033[0;32m[SUCCEED] $test_to_run\033[0m"
    else
        echo -e "\033[0;31m[FAILED] $test_to_run\033[0m"
    fi
}

function main() {
    local -r test_file="$1"
    local -a tests_to_run

    readarray -t tests_to_run <<< "$(on-a-separate-bash read-tests test_file)"
    # shellcheck disable=SC2128
    if [ -z "$tests_to_run" ]; then
        # If the array has an empty first element, then nothing was read
        >&2 echo Failed to read files from "$test_file"
        exit 1
    fi

    for test_to_run in "${tests_to_run[@]}"; do
        on-a-separate-bash run-single-test test_file test_to_run
    done
}

main "$@"
