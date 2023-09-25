#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Propagate exit code on a pipeline
set -x # Print commands and their arguments as they are executed.

# At the time of writing 18.18.0 is the latest LTS
node_version=18.18.0
readonly node_version

# At the time of writing 25.7.0 is the latest Electron
electron_version=25.7.0
readonly electron_version

install_dir="$HOME"/.local/opt
readonly install_dir

nativefier_install_dir="$install_dir"/nativefier
readonly nativefier_install_dir

nvm="$(mktemp)"
readonly nvm

function main() {
    local app_name url

    if [ "$#" -ne 2 ]; then
        >&2 echo Usage "$(basename "$0")" app_name url
        exit 1
    fi

    app_name="$1"
    readonly app_name

    url="$2"
    readonly url

    ensure-node-installed

    /usr/bin/mkdir --parents "$install_dir"

    ensure-latest-nativefier-installed

    nativefier "$url" \
        "$install_dir" \
        --name "$app_name" \
        --electron-version "$electron_version" \
        --single-instance \
        --tray

    install-desktop-shortcut "$app_name"
}

function create-nvm-script() {
    if [ ! -s "$HOME"/.nvm/nvm.sh ]; then
        >&2 echo nvm is not installed
        exit 1
    fi

    /usr/bin/cat << EOF > "$nvm"
#!/bin/bash

export NVM_DIR="\$HOME"/.nvm && source "\$NVM_DIR"/nvm.sh && nvm "\$@"
EOF

    /usr/bin/chmod +x "$nvm"
}

function ensure-node-installed() {
    create-nvm-script

    if ! "$nvm" ls "$node_version"; then
        "$nvm" install "$node_version"
    fi
}

function npm() {
    # --silent is important, otherwise a line "Running node v..."
    # will be printed and mess up some output
    "$nvm" exec --silent "$node_version" npm "$@"
}

function nativefier() {
    "$nvm" exec --silent "$node_version" "$nativefier_install_dir"/node_modules/.bin/nativefier "$@"
}

function ensure-latest-nativefier-installed() {
    /usr/bin/mkdir --parents "$nativefier_install_dir"

    # Look for the `package.json` because we create the dir on the line above
    # which would make `! -e "$nativefier_install_dir"` always return false
    if [ ! -e "$nativefier_install_dir"/package.json ]; then
        npm --prefix "$nativefier_install_dir" install nativefier
    else
        npm --prefix "$nativefier_install_dir" update
    fi
}

function install-desktop-shortcut() {
    local app_name wm_class

    app_name="$1"
    readonly app_name

    # The WM Class value is a string that defines in which class the application is grouped in the launcher
    wm_class="$(npm view "$HOME"/.local/opt/"$app_name"-linux-x64/resources/app name)"
    readonly wm_class

    /usr/bin/cat << EOF > "$HOME"/.local/share/applications/"$app_name".desktop
[Desktop Entry]
Version=1.1
Type=Application
Name=$app_name
Icon=$install_dir/$app_name-linux-x64/resources/app/icon.png
Exec=$install_dir/$app_name-linux-x64/$app_name
StartupNotify=true
StartupWMClass=$wm_class
EOF
}

main "$@"
