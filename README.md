
# monitoring-app
Bachelor's Thesis monitoring Kubernetes App using HELM, Flux, K9s, Grafana and Prometheus

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
Run each code block separately
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

### Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
```bash
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $HOME/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
```

### Install Kubernetes CLI, K9s, HELM, Minikube
```bash
brew install helm 
brew install k9s
brew install kubernetes-cli
brew install minikube
minikube start
```

### Add needed Helm Repos
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### Installing & Configuring Flux CD
Install Flux CLI
```bash
brew install fluxcd/tap/flux
. <(flux completion bash)
```
Guide to add SSH key to Github account(s)
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<ssh-key-name>
cat ~/.ssh/<ssh-key-name>
```
Guide to bootstrap Flux with Github
https://fluxcd.io/flux/installation/bootstrap/github/
Namely, I use the method below
```bash
flux bootstrap git \
  --url=ssh://git@github.com/<org>/<repository> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

### Create Namespaces for the apps
```bash
kubectl create namespace prometheus
kubectl create namespace loki-promtail
kubectl create namespace grafana
```
### Install Apps using Helm
Installing Grafana in its own namespace:
```bash
helm install grafana-app grafana/grafana --namespace grafana
```
Installing Loki-Promtail Stack in its own namespace:
```bash
helm install loki-promtail-stack-app grafana/loki-stack --namespace grafana
```
Installing Prometheus in its own namespace:
```bash
helm install prometheus-app prometheus-community/prometheus --namespace prometheus
```
Installing Prometheus Node Exporter in the Prometheus namespace:
```bash
helm install prom-node-exporter prometheus-community/prometheus-node-exporter --namespace prometheus
```
Installing Prometheus Redis Exporter in the Prometheus namespace:
```bash
helm install prom-redis-exporter prometheus-community/prometheus-node-exporter --namespace prometheus
```
Installing Prometheus Systemd Exporter in the Prometheus namespace:
```bash
helm install prom-systemd-exporter prometheus-community/prometheus-systemd-exporter --namespace prometheus
```
Installing Prometheus Nginx Exporter in the Prometheus namespace:
```bash
helm install prom-nginx-exporter prometheus-community/prometheus-nginx-exporter --namespace prometheus
```
Installing Prometheus MySQL Exporter in the Prometheus namespace:
```bash
helm install prom-mysql-exporter prometheus-community/prometheus-mysql-exporter --namespace prometheus
```