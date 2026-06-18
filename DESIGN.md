# VraiSetup Design
------------------

## Introduction

The propose of this repository is to be able to setup my standard environment with little to no effort by describing it in text files that are revision controlled. Ideally system level setup (ex: anything that needs `sudo`) would be described in a sort of container image and the user configuration via something less rigid, but given the container image approach is not valid at this time, using [Ansible](https://ansible.com) for everything sounds like a good compromise.

## Approach

I utilize multiple computers in my daily life, both at home and at work. Ideally both should work the same regardless of whether is a text only mode or a GUI and across multiple distributions. Additionally, some of these computers at work are [cattle servers](https://devops.stackexchange.com/a/654) which means I should be able to perform minimal text only setup remotely.

So the setup then boils down to the following environments:

1. Common TUI user level personalization.
2. Common GUI personalization.
    1. System level applications/infrastructure.
    2. Individual user applications.
3. Personal system level personalization.
4. Personal GUI applications.
    - This implies #2.

That way, when I spin up a new instance at work or a virtual machine at home, I can just run the ansible setup for #1 and be ready to go. #3 and #4 should leverage technologies like Snap and Flatpak as much as possible to ensure they are portable.

## Proposal

The `ansible` directory is to contain 4 directories matching the list above, with the same order:

- `0-common-tui`
- `1-common-gui`
- `3-personal-system`
- `4-personal-gui-root`
- `5-personal-gui`

Note `3-personal-system` and `4-personal-gui` are the only entries to require root permissions, everything else should be able to be run as my own user. Note that these are distro specific as well, the rest should be extremely portable.

## About distribution platforms

Acquiring software from upstream is a highly desired characteristic as it cuts the middle man of the distro allowing to get the latest version of the software, this was already pionereed by [Ubuntu when they decided to ship Firefox as a Snap rather than a `deb` package](https://discourse.ubuntu.com/t/feature-freeze-exception-seeding-the-official-firefox-snap-in-ubuntu-desktop/24210?utm_source=chatgpt.com) and while it was somewhat unpopular I have used the same model for my browser with Flatpak and I'm satisfied.

A second highly desirable feture is portability, for GUI applications this is accomplished using one of the universal formats ([AppImage](https://appimage.org), [Flatpak](https://flatpak.org) and [Snap](https://snapcraft.io)). The primary option is Flatpak with its autoupdate feature and integration with desktop environments and highly configurable sandbox. The next option is Snap which continues the auto update feature. The last preference is AppImage which lacks built in autoupdate but some applications may include it.

If an application is not officially shipped in a portable format then the non portable format is preferred, again to cut the middlmen.

