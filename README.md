
# monitoring-app
Bachelor's Thesis monitoring Kubernetes App using HELM, K9s, Grafana and Prometheus

## Installation

### Prerequisites & Requirements
4-core CPU \
4GB RAM \
15-30GB Storage \
Linux-based OS - in my project I use Ubuntu 22.04 LTS

### Update the system & Install essential DEV package

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential
```
### Add Docker to the Package Manager & Install it

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get install ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc && echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \

$(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker && sudo usermod -aG docker $USER && newgrp docker
```
### Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/ubuntu/.bashrc

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install gcc -y
```

### Install Minikube, Kubernetes CLI, K9s, HELM 
```bash
brew install minikube -y
brew install kuberenetes-cli -y
brew install helm -y 
brew install k9s -y
```

### Start Minikube
```bash
minikube start
```

### Add needed Helm Repos
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add my-repo https://charts.bitnami.com/bitnami
```
