# README

This is a prototype to move this whole repository to Ansible playbooks.

1. Install ansible with `sudo apt --update install ansible-core python3-psutil`
    - The `python3-psutil` package is required for the Gnome setup
2. Run the playbooks without any inventory and ask for `sudo` password: `ansible-playbook --ask-become-pass 000-flatpak.yaml`

Note: Ensure not to run inside `VSCode` as the home directory gets messed up due the Snap nature of VSCode
