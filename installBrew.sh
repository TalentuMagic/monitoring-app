#!/bin/bash
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