#!bin/bash
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

# Homebrew
echo "Installing Homebrew...";
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/ubuntu/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc -y
echo "Done";

# K9s kubectl helm minikube
echo "Installing Kubernetes-CLI, MiniKube, Helm and K9s...";
brew install kuberenetes-cli -y
brew install minikube -y
brew install helm -y 
brew install k9s -y
echo "Done";
echo 

# starting minikube
minikube start

# add Helm repos
echo "Adding Helm Repos...";
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo "Done";
echo
