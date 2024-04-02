#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
test -n "$VRAI_DEBUG" && set -x # Print commands and their arguments as they are executed.

while IFS= read -r __test_function; do
    echo -e "\033[0;33mRunning test $__test_function...\033[0m"

    if "$__test_function"; then
        echo -e "\033[0;32m[SUCCEED] $__test_function\033[0m"
    else
        __tests_failed=true
        echo -e "\033[0;31m[FAILED] $__test_function\033[0m"
    fi
done < <(declare -F | cut --delimiter=' ' --field=3 | grep '^test-')

if [ "$__tests_failed" = true ]; then
    exit 1
fi
