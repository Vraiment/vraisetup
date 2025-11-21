# VraiSetup

This repository contains a suite of Ansible playbooks to setup my environment the way I want it.

## Prerequisites

This requires [Ansible](https://ansible.com) to be installed, some of the Gnome setup requires `python3-psutil` as well:

```shell
sudo apt --update install ansible-core python3-psutil
```

## Installing

This is as simple as running Ansible with the permissions necessary to run as root:

```shell
ansible-playbook --ask-become-pass ansible/*.yaml
```
