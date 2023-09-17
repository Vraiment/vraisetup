# 1Password
-----------

The 1Password desktop client can [be installed via `apt`, Snap and Flatpak](https://support.1password.com/install-linux), however at the time of writing there is this warning on the last two:

> The latest release of 1Password for Linux available in the Snap Store is currently outdated.
> 
> To update 1Password if you installed it from the Snap Store, uninstall 1Password, then reinstall the app with a different installation method.

So we need to install via `apt`, the instructions are as follows:

```shell
# Add the key for the 1Password apt repository:
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

# Add the 1Password apt repository:
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list

# Add the debsig-verify policy:
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Install 1Password:
sudo apt update && sudo apt install 1password
```

Because this repository contains some files that are ready out of the box, the keyring, repository list and policies were prefetched with a slight modification of the above script, like this:

```shell
wget -O- https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output 1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' > 1password.list
wget -O- https://downloads.1password.com/linux/debian/debsig/1password.pol > 1password.pol
```

The policy key is not download as it is the same as the keyring key.
