#!/bin/bash
# Initialize Kubernetes control plane
set -euxo pipefail

# Set variables
NODENAME=$(hostname -s)
# Important: For Calico, use 10.244.0.0/16 as the pod CIDR
POD_CIDR="10.244.0.0/16"

# Get the IP of the host-only interface for cluster communication
MASTER_IP=$(ip -o -4 addr list enp0s8 | awk '{print $4}' | cut -d/ -f1)

# Set the container runtime interface (CRI) socket for containerd
CRI_SOCKET="unix:///run/containerd/containerd.sock"

# Pull required images
sudo kubeadm config images pull --cri-socket="$CRI_SOCKET"

# Check if Kubernetes is already initialized
if [ -d "/etc/kubernetes/manifests" ]; then
  echo "Kubernetes appears to be initialized. Performing a safe reset..."
  
  # Reset Kubernetes and clean up
  sudo kubeadm reset -f --cri-socket="$CRI_SOCKET" || {
    echo "Failed to reset Kubernetes cluster. Check logs for details."
    exit 1
  }
  sudo rm -rf /etc/cni/net.d
  sudo rm -rf "$HOME/.kube"
  sudo rm -rf /var/lib/etcd

  # Clean up iptables rules
  echo "Cleaning up iptables rules..."
  sudo iptables -F
  sudo iptables -X
  sudo iptables -t nat -F
  sudo iptables -t nat -X
  sudo iptables -t mangle -F
  sudo iptables -t mangle -X

  # Clean up IPVS tables
  if command -v ipvsadm &> /dev/null; then
    echo "Cleaning up IPVS tables..."
    sudo ipvsadm --clear
  else
    echo "ipvsadm not found. Skipping IPVS cleanup."
  fi

  # Restart container runtime and kubelet
  sudo systemctl restart containerd kubelet
else
  echo "Kubernetes is not initialized. Skipping reset and cleanup steps."
fi

# Verify kubelet status
echo "Checking kubelet status..."
if ! systemctl is-active --quiet kubelet; then
  echo "Kubelet is not running. Attempting to start kubelet..."
  sudo systemctl start kubelet
  if ! systemctl is-active --quiet kubelet; then
    echo "Failed to start kubelet. Check 'systemctl status kubelet' and 'journalctl -xeu kubelet' for details."
    exit 1
  fi
fi

# Ensure required cgroups are enabled
echo "Checking cgroup configuration..."
if ! grep -q "cgroup" /proc/filesystems; then
  echo "Required cgroups are not enabled. Ensure your system supports cgroups and they are properly configured."
  exit 1
fi

# Debugging: List all Kubernetes containers
echo "Listing all Kubernetes containers..."
sudo crictl --runtime-endpoint "$CRI_SOCKET" ps -a | grep kube || echo "No Kubernetes containers found."

# Additional debugging for kubelet and container runtime
echo "Debugging kubelet and container runtime..."
sudo systemctl status kubelet || echo "Failed to retrieve kubelet status."
sudo journalctl -xeu kubelet || echo "Failed to retrieve kubelet logs."
sudo crictl --runtime-endpoint "$CRI_SOCKET" ps -a || echo "Failed to list containers."

# Initialize the control plane
sudo kubeadm init \
  --apiserver-advertise-address="$MASTER_IP" \
  --apiserver-cert-extra-sans="$MASTER_IP" \
  --pod-network-cidr="$POD_CIDR" \
  --node-name "$NODENAME" \
  --ignore-preflight-errors Swap,Port-6443,Port-10259,Port-10257,Port-10250,Port-2379,Port-2380,FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml,FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml,FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml,FileAvailable--etc-kubernetes-manifests-etcd.yaml,DirAvailable--var-lib-etcd \
  --cri-socket="$CRI_SOCKET" || {
    echo "Kubeadm initialization failed. Check logs for details."
    echo "Run 'journalctl -xeu kubelet' and 'crictl logs' for further debugging."
    exit 1
  }

# Configure kubectl for the current user
mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Remove the control-plane taint if you want to run workloads on the master node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-