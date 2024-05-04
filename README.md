
# monitoring-app
Bachelor's Thesis monitoring Kubernetes App using HELM, Flux, K9s, Grafana and Prometheus

## Installation

### Prerequisites & Requirements
4-core CPU \
4GB RAM \
15-30GB Storage \
Linux-based OS - in my project I use Ubuntu 22.04 LTS

### 1. Update the system & Install essential DEV package

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential
```
### 2. Add Docker to the Package Manager & Install it
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
### 2.1 Make sure Docker has the proper MTU size in relation to the VM
_The preferred MTU for most cases is 1450_
Create the Docker daemon config file
```bash
sudo nano ~/etc/docker/daemon.json
```
Copy this to the file & save it
```json
{
  "mtu":1450
}
```
Restart Docker service
```bash
sudo systemctl restart docker
```

### 3. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
```bash
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $HOME/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
```

### 4. Install Kubernetes CLI, K9s, HELM, Minikube
```bash
brew install helm 
brew install k9s
brew install kubernetes-cli
brew install minikube
minikube start
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
minikube addons enable metrics-server
kubectl config set-context --current --namespace=all
```

### 5. Add needed Helm Repos
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### 6. Installing & Configuring Flux CD
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

### 7. Create Namespaces for the apps
```bash
kubectl create namespace prometheus-grafana
kubectl create namespace nginx-ingress
```
#### Example to Install Default Apps using Helm (optional/TEST only)
Installing Grafana in its own namespace:
```bash
helm install grafana-app grafana/grafana --namespace grafana
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
### 8. Create the directories for each app & config files
## 8.1 For kubeEtcd, kubeScheduler, kubeControllerManager fix -> https://github.com/prometheus-community/helm-charts/issues/1966 ; https://github.com/prometheus-community/helm-charts/issues/1966#issuecomment-1093316897
## 8.2 For each app create the following files in each folder:
- gitrepository.yaml
- kustomization.yaml
- kustomizeconfig.yaml
- <dir_name>-values.yaml
- service.yaml
# Optional / If persistence is needed
- pvc.yaml
### 8.x After creating the config files, run the following command to init each HelmRelease for each app
```bash
kubectl apply -k .
```
e.g. ```bash
~/monitoring-app/apps/prometheus-app/$ kubectl apply -k .
```
