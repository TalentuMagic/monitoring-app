
# monitoring-app
Bachelor's Thesis monitoring Kubernetes App using HELM, Flux, K9s, Grafana and Prometheus

# Contents
1. [Installation on Cluster VM side](#installation-on-cluster-vm-side)
   1. [Update the system & Install essential DEV package](#1-update-the-system--install-essential-dev-package)
   2. [Add Docker to the Package Manager & Install it](#2-add-docker-to-the-package-manager--install-it)
2. [Installation on Client VM side](#installation-on-client-vm-side)

---

### If needed, create a SOCKS connection to the VM if its behind a firewall
```ps
ssh -D 1337 -q -C -N user@domain.com
```
On Windows, go to `Internet Options` -> `Connections` -> `Lan Settings` and tick the `Proxy Server`.
Click `Advanced` and in the `Socks` field add `localhost` to Proxy Address field and `1337` to Port field (if needed, untick `Use the same proxy server for all protocols`) and hit `OK`.

---

## Installation on Cluster VM side

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
#### 4.1 Configure Kubernetes Scheduler, Etcd, Controller to be accessible from any address (if in Prometheus Targets appear as down)
##### For kubeEtcd, kubeScheduler, kubeControllerManager fix, for more explanations -> https://github.com/prometheus-community/helm-charts/issues/1966 ; https://github.com/prometheus-community/helm-charts/issues/1966#issuecomment-1093316897
```bash
minikube ssh
cd /etc/kubernetes/manifests
```
Using vim, edit the following:
`--listen-metrics-urls=http://127.0.0.1:2381`
to
`--listen-metrics-urls=http://0.0.0.0:2381`
and below in the manifest file in the sections `livenessProbe` and `startupProbe` replace IP Address 127.0.0.1 to 0.0.0.0

In kube-controller-manager.yaml manifest you should change IP 127.0.0.1 to 0.0.0.0 in `--bind-address` argument
Also change this argument in the kube-scheduler.yaml manifest.

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
kubectl create namespace prometheus
```
#### Example to Install Default Apps using Helm (optional/TEST only)
Installing Prometheus in its own namespace:
```bash
helm install prometheus-app prometheus-community/prometheus --namespace prometheus
```
### 8. Create the directories for each app & config files
#### 8.2 For each app create the following files in each folder:
- gitrepository.yaml
- kustomization.yaml
- kustomizeconfig.yaml
- <dir_name>-values.yaml
- service.yaml
#### Optional / If persistence is needed
- pvc.yaml
### 8.3 After creating the config files, run the following command to init each HelmRelease for each app
```bash
kubectl apply -k .
```
e.g. _~/monitoring-app/apps/prometheus-app/$ kubectl apply -k ._

### 9. To import Grafana Dashboards -> https://grafana.com/grafana/dashboards/
### 10. To access the apps from the browser, I use an NGINX Load-Balancer
Install NGINX
```bash
sudo apt install nginx
```
Configure NGINX server for Grafana pod at the path using the following command `sudo nano /etc/nginx/sites-available/grafana` and the configuration below:
```nginx
server {
    listen 3000;

    location / {
        proxy_set_header Host 192.168.49.2:30443;
        proxy_set_header Origin http://192.168.49.2:30443;
        proxy_pass http://192.168.49.2:30443;
    }
}
```
Save and close the file. Run this command afterwards `sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/`
Do the same for Prometheus `sudo nano /etc/nginx/sites-available/prometheus`
```nginx
# Prometheus Server
server {
    listen 9090;

    location / {
        proxy_set_header Host 192.168.49.2:30090;
        proxy_set_header Origin http://192.168.49.2:30090;
        proxy_pass http://192.168.49.2:30090;
    }
}
# Prometheus AlertManager
server {
    listen 9093;

    location / {
        proxy_set_header Host 192.168.49.2:30903;
        proxy_set_header Origin http://192.168.49.2:30903;
        proxy_pass http://192.168.49.2:30903;
    }
}
```
Save and close the file. Run this command afterwards `sudo ln -s /etc/nginx/sites-available/prometheus /etc/nginx/sites-enabled/`
Restart the NGINX server using `sudo systemctl restart nginx`
---

## Installation on Client VM side
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

## 3. Install MySQL, Install & Configure MySQL Exporter to scrape data
### 3.1 Create the following directories
```bash
mkdir containers archives exporters
```
### 3.2 Pull MySQL Exporter archive & Extract it (https://github.com/prometheus/mysqld_exporter/releases/)
```bash
wget -P ~/archives/ https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xvfz ~/archives/mysqld_exporter-*.linux-amd64.tar.gz
mv ~/archives/mysqld_exporter-0.15.1.linux-amd64/ ~/exporters
```
### 3.3 Create the config file for the MySQL Exporter & Run it
```bash
nano ~/exporters/mysqld_exporter-0.15.1.linux-amd64/.my.cnf
```
```config
[client]
user=exporter
password=admin
```
Save and close the file
### 3.4 Create the Docker compose file for the MySQL DB & Run it
```bash
cd ~/containers
mkdir mysql
cd mysql/
nano compose.yaml
```
```yaml
services:
  db:
    image: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootadmin
      MYSQL_DATABASE: clientDB
      MYSQL_USER: user1
      MYSQL_PASSWORD: admin
    ports:
      - 3306:3306
    volumes:
      - db-data:/var/lib/mysql
volumes:
  db-data:
```
Save the file and exit
Run `docker-compose up -d` to start your MySQL DB container in detached-mode

### 3.5 Create the "exporter" user for data scraping
Open MySQL container shell
```bash
docker container ls
```
Copy the container hash
Run the following command to enter the shell of the container
```bash
docker exec -it <container_hash> /bin/bash
```
When inside the container shell, run the following commands
```bash
mysql -u root -p
```
Enter the password you set earlier (e.g. rootadmin)
Run the following SQL commands
```sql
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'admin' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;
```
### 3.6 Run the MySQL Exporter

#### 3.6.1 Run the MySQL Exporter in the background
```bash
cd
./exporters/mysqld_exporter-0.15.1.linux-amd64/mysqld_exporter &
```
You can use CTRL+C to exit the shell - the script will still run in the background
To kill the process, run the following commands
```bash
pgrep mysqld_exporter
kill -9 <PID>
```
#### 3.6.2 Run the MySQL Exporter as a service
Create the service config
```bash
sudo nano /etc/systemd/system/mysqld-exporter
```
Paste the following into the config file & Save it
```config
[Unit]
Description=MySQL Exporter Service - scrapes MySQL DB data

[Service]
User=ubuntu
WorkingDirectory=~/exporters/mysqld_exporter-0.15.1.linux-amd64/
ExecStart=mysqld_exporter
# optional items below
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```
Reload daemons
```bash
sudo systemctl daemon-reload
```
Enable (autorun at OS startup) and start the service
```bash
sudo systemctl start mysqld-exporter
sudo systemctl enable --now mysqld-exporter
sudo systemctl status mysqld-exporter
```