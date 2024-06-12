
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

### 4. Install Kubernetes CLI, K9s, HELM, Minikube & configure Minikube storage
```bash
brew install helm 
brew install k9s
brew install kubernetes-cli
brew install minikube
minikube config set cpus 3
minikube config set memory 2440
minikube start --bootstrapper=kubeadm --extra-config=scheduler.bind-address=0.0.0.0 --extra-config=controller-manager.bind-address=0.0.0.0 --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook
minikube addons enable volumesnapshots
minikube addons enable csi-hostpath-driver
minikube addons disable storage-provisioner
minikube addons disable default-storageclass
kubectl config set-context --current --namespace=all
kubectl patch storageclass csi-hostpath-sc -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
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
Configure Default NGINX server file to forward traffic to SSL/TLS encrypted endpoints
```nginx
# when accessing from HTTP
server {
    listen 80;
    server_name 10.9.0.164;
    server_tokens off;

    location / {
        return 301 https://$host;
    }

    location = /grafana {
        return 301 https://$host:3000$request_uri;
    }

    location = /prometheus {
        return 301 https://$server_name:9090;
    }
    location = /alertmanager {
        return 301 https://$server_name:9093;
    }
}
# when accessing from HTTPS
server {
    listen 443 ssl http2;
    server_name 10.9.0.164;
    server_tokens off;

    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    location / {
        deny all;
    }

    location = /grafana {
        return 301 https://$host:3000$request_uri;
    }

    location = /prometheus {
        return 301 https://$server_name:9090;
    }
    location = /alertmanager {
        return 301 https://$server_name:9093;
    }
}
```
Configure the self-signed certificate for TLS encryption (https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04)
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
sudo nano /etc/nginx/snippets/self-signed.conf
```
Add the following lines to the file
```nginx
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
```
Create the config snippet with Strong Encryption Settings
```bash
sudo nano /etc/nginx/snippets/ssl-params.conf
```
```nginx
# from https://cipherli.st/
# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/ssl/certs/dhparam.pem;
```
Configure NGINX server for Grafana pod at the path using the following command `sudo nano /etc/nginx/sites-available/grafana` and the configuration below:
```nginx
server {
    listen 3000 ssl http2;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    server_tokens off;

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
    listen 9090 ssl http2;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    server_tokens off;

    location / {
        proxy_set_header Host 192.168.49.2:30090;
        proxy_set_header Origin http://192.168.49.2:30090;
        proxy_pass http://192.168.49.2:30090;
    }
}
# Prometheus AlertManager
server {
    listen 9093 ssl http2;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    server_tokens off;

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

## 3. Install Blackbox Exporter & Configure it to scrape data
### 3.1 Create the `compose.yaml` file for Blackbox Exporter
```yaml
services:
  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    volumes:
      - ./blackbox.yaml:/etc/blackbox_exporter/config.yml
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
    ports:
      - 9115:9115
    restart: unless-stopped
```
### 3.2 Create the configuration file `blackbox.yaml` for Blackbox Exporter
```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: [HTTP/1.1, HTTP/2]
      method: GET
      fail_if_ssl: false
  http_probe:
    prober: http
    timeout: 5s
    http:
      method: GET
      valid_http_versions: [HTTP/1.1, HTTP/2]
      fail_if_ssl: false
  post_probe:
    prober: http
    timeout: 5s
    http:
      method: POST
      valid_http_versions: [HTTP/1.1, HTTP/2]
      fail_if_ssl: false
  put_probe:
    prober: http
    timeout: 5s
    http:
      method: PUT
      valid_http_versions: [HTTP/1.1, HTTP/2]
      fail_if_ssl: false
  delete_probe:
    prober: http
    timeout: 5s
    http:
      method: DELETE
      valid_http_versions: [HTTP/1.1, HTTP/2]
      fail_if_ssl: false
  tcp_probe:
    prober: tcp
    timeout: 5s
```
### Save the files and exit; Run `docker-compose up -d` to start the Blackbox Exporter container in detached-mode

## 4. Install MySQL, Install & Configure MySQL Exporter to scrape data
### 4.1 Create the `compose.yaml` file for the MySQL DB and MySQL Exporter
```yaml
services:
  db:
    image: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: clientDB
      MYSQL_USER: user1
      MYSQL_PASSWORD: admin
    ports:
      - 3306:3306
    volumes:
      - mysql-data:/var/lib/mysql
      - ./exporter.sql:/docker-entrypoint-initdb.d/exporter.sql

  mysql-exporter:
    image: prom/mysqld-exporter
    command:
      - "--config.my-cnf=/etc/mysql/mysql.conf.d/my.cnf"
      - '--collect.info_schema.innodb_metrics'
      - '--collect.auto_increment.columns'
      - '--collect.info_schema.processlist'
      - '--collect.binlog_size'
      - '--collect.info_schema.tablestats'
      - '--collect.global_variables'
      - '--collect.info_schema.query_response_time'
      - '--collect.info_schema.userstats'
      - '--collect.info_schema.tables'
      - '--collect.perf_schema.tablelocks'
      - '--collect.perf_schema.file_events'
      - '--collect.perf_schema.eventswaits'
      - '--collect.perf_schema.indexiowaits'
      - '--collect.perf_schema.tableiowaits'
      - '--collect.slave_status'
    volumes:
      - ./my.cnf:/etc/mysql/mysql.conf.d/my.cnf:ro
    ports:
      - 9104:9104
    depends_on:
      - db

volumes:
  mysql-data:
```
### 4.2 Create a `exporter.sql` script that will be executed when the MySQL DB container starts
This script creates the `exporter` user that will do periodical queries on the DB as the MySQL Exporter requires
```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY 'exporteradmin';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
```
### 4.3 Create a `my.cnf` configuration file for the MySQL Exporter
This file configures MySQL Exporter with the credentials for the user on the MySQL DB that will do queries and send data back to the exporter
```conf
[client]
user=exporter
password=exporteradmin
host=db
```
### Save the files and exit; Run `docker-compose up -d` to start your MySQL DB and MySQL Exporter containers in detached-mode

## 5. Node Exporter
### 5.1 Create the `compose.yaml` file for Node Exporter
```yaml
services:
  node-exporter:
    image: prom/node-exporter:latest
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
      - '--collector.systemd'
    ports:
      - 9100:9100
    restart: unless-stopped
```
### Save the file and exit; Run `docker-compose up -d` to start your Node Exporter container in detached-mode

## 6. Node Exporter
### 6.1 Create the `compose.yaml` file for the NodeJS application, the NGINX server, and the NGINX Exporter
```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - 80:80
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - node_app
    restart: unless-stopped
    networks:
      nginx_exporter_net:

  node_app:
    image: node:latest
    container_name: node_app
    command: node app.js
    volumes:
      - ./nodejs-app/:/app
    working_dir: /app
    expose:
      - 3000
    restart: unless-stopped
    networks:
      nginx_exporter_net:

  nginx_prometheus_exporter:
    image: nginx/nginx-prometheus-exporter:latest
    container_name: nginx_prometheus_exporter
    command:
      - '--nginx.scrape-uri=http://nginx:80/stub_status'
    ports:
      - 9113:9113
    depends_on:
      - nginx
    restart: unless-stopped
    networks:
      nginx_exporter_net:
        ipv4_address: 172.28.1.4
networks:
  nginx_exporter_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
```
### 6.2 Create the NGINX Configuration file `nginx.conf`
This configures the NGINX server to act as a Load Balancer
```conf
worker_processes 2;

events { worker_connections 1024; }

http {
    server_tokens off;

    upstream nodejs {
        server node_app:3000;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://nodejs;
        }

        location /stub_status {
            stub_status;
            allow 172.28.1.4;
            deny all;
        }
    }
}
```
### 6.3 Create the NodeJS application in its separate folder `nodejs-app/app.js`
```js
const http = require('http');

const hostname = '0.0.0.0';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World!\n');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
```
### Save the file and exit; Run `docker-compose up -d` to start your NodeJS application, NGINX LoadBalancer, and NGINX Exporter containers in detached-mode