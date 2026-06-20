# VraiSetup Design
------------------

## Introduction

The propose of this repository is to be able to setup my standard environment with little to no effort by describing it in text files that are revision controlled. Ideally system level setup (ex: anything that needs `sudo`) would be described in a sort of container image and the user configuration via something less rigid, but given the container image approach is not valid at this time, using [Ansible](https://ansible.com) for everything sounds like a good compromise.

## Wants

### Cattle servers setup

I utilize multiple computers in my daily life, both at home and at work. Ideally both should work the same regardless of whether is a text only mode or a GUI and across multiple distributions. Additionally, some of these computers at work are [cattle servers](https://devops.stackexchange.com/a/654) which means I should be able to perform minimal text only setup remotely. So for my command line setup I want a small set of portable runbooks that I can just and hit the ground running.

These runbooks should list their minimal dependencies (for example: `ansible-playbook`). These can be called `tui-core` and for convenience a per-distro `tui-core-base` can exist to ensure the dependencies are available, ideally if `tui-core` has been already been setup and an update is required just running the `tui-core` playbooks should be enough, `tui-core-base` even if idempotent shouldn't be required to be rerun.

### GUI

For the GUI things are similar, multiple machines that I'd like to keep the same setup, but is more complicated given that this may be distribution and version dependent, specially for the system level components. User level components, specially relying on things like [AppImage](https://appimage.org) or [Flatpak](https://flatpak.org) are very portable and require no root access.

Here are some desired qualities:
    - The only dependency for these should be `ansible-playbook` as any additional dependency can be described with playbooks itself.
    - It should be divided in two: system level setup and user level setup. Conceptually these should match the setup of a root partition (`/`) vs a home partition (`/home`).
    - Each individual playbook should be focused on features, for example: being able to run `flatpak`.
    - System level setup should be per distro and per version.

## About distribution platforms

Acquiring software from upstream is a highly desired characteristic as it cuts the middle man of the distro allowing to get the latest version of the software, this was already pionereed by [Ubuntu when they decided to ship Firefox as a Snap rather than a `deb` package](https://discourse.ubuntu.com/t/feature-freeze-exception-seeding-the-official-firefox-snap-in-ubuntu-desktop/24210?utm_source=chatgpt.com) and while it was somewhat unpopular I have used the same model for my browser with Flatpak and I'm satisfied.

A second highly desirable feture is portability, for GUI applications this is accomplished using one of the universal formats ([AppImage](https://appimage.org), [Flatpak](https://flatpak.org) and [Snap](https://snapcraft.io)). The primary option is Flatpak with its autoupdate feature and integration with desktop environments and highly configurable sandbox. The next option is Snap which continues the auto update feature. The last preference is AppImage which lacks built in autoupdate but some applications may include it.

If an application is not officially shipped in a portable format then the non portable format is preferred, again to cut the middlmen.
