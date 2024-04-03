#!/bin/bash
# Homebrew
home_dir=$(eval echo ~$USER);
echo "Installing Homebrew...";
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> "$home_dir"/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
echo "Done";

# K9s kubectl helm minikube
echo "Installing Kubernetes-CLI, MiniKube, Helm and K9s...";
brew install kuberenetes-cli
brew install minikube
brew install helm
brew install k9s
echo "Done"
echo 

# add Helm repos
echo "Adding Helm Repos...";
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo "Done";
echo