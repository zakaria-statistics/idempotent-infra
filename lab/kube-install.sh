#!/bin/bash
# Install Kubernetes components
set -euxo pipefail

# Set version variables
KUBERNETES_VERSION="v1.30"
KUBERNETES_INSTALL_VERSION="1.30.0-1.1" # Adjust version as needed

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubectl, and kubeadm
sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_INSTALL_VERSION" kubectl="$KUBERNETES_INSTALL_VERSION" kubeadm="$KUBERNETES_INSTALL_VERSION"
sudo apt-mark hold kubelet kubeadm kubectl

# Configure kubelet to use the host-only interface
HOST_IP=$(ip -o -4 addr list enp0s8 | awk '{print $4}' | cut -d/ -f1)
echo "KUBELET_EXTRA_ARGS=--node-ip=$HOST_IP" | sudo tee /etc/default/kubelet

# Restart kubelet to apply changes
sudo systemctl restart kubelet