
## Installation instructions

This repository contains a suite of scripts and configuration files to install Ubuntu the way I want it.

To run, just copy and paste the following on an minimal Ubuntu 22.04 installation:

```shell
ARCHIVE=$(mktemp)
BRANCH=master

wget -O "$ARCHIVE" https://github.com/Vraiment/vraisetup/archive/refs/heads/"$BRANCH".zip && \
    unzip "$ARCHIVE" -d "$HOME"/.local/src && \
    "$HOME"/.local/src/vraisetup-"$BRANCH"/bin/ubuntu.sh
```
