# Docker
--------

Docker can be installed via `snap`  or a Docker provided repository. While having Docker as a Snap would be ideal it doesn't seem to be official. There's also the issue that Docker is pushing for `docker-desktop` which I really don't want to install.

The [official instructions](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository), recommends the following steps to configure the apt repository:

```shell
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

Followed by the following command to install Docker itself:

```shell
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
