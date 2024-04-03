#!/bin/bash
echo "Running the script to install and configure prerequisites for Monitoring Kubernetes Stack...";
echo "Updating and Upgrading the system...";
apt update && apt upgrade -y;
apt install build-essential -y;
echo "Done";
echo

# Docker
echo "Installing Docker...";
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done;
apt-get install ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc && echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update;
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y;
groupadd docker && sudo usermod -aG docker $USER && newgrp docker;
echo "Done";
echo