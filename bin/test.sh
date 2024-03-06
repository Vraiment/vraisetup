#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

nvm_path=$(mktemp)

cat << EOF > "$nvm_path"
#!/bin/bash

export NVM_DIR="\$HOME"/.nvm && source "\$NVM_DIR"/nvm.sh && nvm "\$@"
EOF

chmod +x "$nvm_path"

function nvm() {
    "$nvm_path" "$@"
}

nvm --version
