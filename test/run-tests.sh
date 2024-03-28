#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

while IFS= read -r __test_function; do
    echo Running test "$__test_function"

    if "$__test_function"; then
        echo '[SUCCEED]'
    else
        echo '[FAILED]'
    fi
done < <(declare -F | cut --delimiter=' ' --field=3 | grep '^test-')
