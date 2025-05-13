Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.define "kube" 

    config.vm.provider "virtualbox" do |vb|
        vb.name = "kube" 
        vb.memory = "6144"
        vb.cpus = 10
    end

    # Configure disk size using vagrant-disksize plugin
    config.disksize.size = "50GB"

    # Host-only network (static IP for Kubernetes)
    config.vm.network "private_network", ip: "192.168.56.10"

    # Sync folder disabled
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # Add SSH key for logging into the VM (Windows-compatible path)
    config.vm.provision "file", source: "C:/Users/#{ENV['USERNAME']}/.ssh/id_rsa.pub", destination: "/tmp/authorized_key_to_add"
    config.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      touch /home/vagrant/.ssh/authorized_keys
      cat /tmp/authorized_key_to_add >> /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    SHELL

    # Provision the VM using separate scripts
    config.vm.provision "file", source: "scripts/configure-netplan.sh", destination: "/tmp/configure-netplan.sh"
    config.vm.provision "file", source: "scripts/configure-dns.sh", destination: "/tmp/configure-dns.sh"
    config.vm.provision "file", source: "scripts/install-containerd.sh", destination: "/tmp/install-containerd.sh"
    config.vm.provision "file", source: "scripts/kube-preparation.sh", destination: "/tmp/kube-preparation.sh"
    config.vm.provision "file", source: "scripts/kube-install.sh", destination: "/tmp/kube-install.sh"
    config.vm.provision "file", source: "scripts/kube-start.sh", destination: "/tmp/kube-start.sh"
    config.vm.provision "file", source: "scripts/gen-docker-secret.sh", destination: "/tmp/gen-docker-secret.sh"
    config.vm.provision "file", source: "scripts/gen-git-secret.sh", destination: "/tmp/gen-git-secret.sh"
    config.vm.provision "file", source: "manifests/calico.yaml", destination: "/tmp/calico.yaml"
    config.vm.provision "file", source: "manifests/namespaces.yaml", destination: "/tmp/namespaces.yaml"
    config.vm.provision "file", source: "manifests/namespaces-quotas.yaml", destination: "/tmp/namespaces-quotas.yaml"
    config.vm.provision "file", source: "tools/kaniko-job.yaml", destination: "/tmp/kaniko-job.yaml"
    config.vm.provision "file", source: "tools/kaniko-config.yaml", destination: "/tmp/kaniko-config.yaml"


    
    # Make the scripts executable and idempotent
    config.vm.provision "shell", inline: <<-SHELL
      set -euxo pipefail

      # Netplan: check if netplan config already applied (example: check for a custom marker file)
      if ! grep -q '192.168.56.10' /etc/netplan/*.yaml; then
        sudo bash /tmp/configure-netplan.sh
      fi

      # DNS: check if /etc/resolv.conf contains expected DNS (example: 8.8.8.8)
      if ! grep -q '8.8.8.8' /etc/resolv.conf; then
        sudo bash /tmp/configure-dns.sh
      fi

      # containerd: check if installed
      if ! command -v containerd >/dev/null 2>&1; then
        sudo bash /tmp/install-containerd.sh
      fi

      # kubeadm: check if installed
      if ! command -v kubeadm >/dev/null 2>&1; then
        sudo bash /tmp/kube-preparation.sh
        sudo bash /tmp/kube-install.sh
      fi

      # init kubeadm: check if already initialized
      if ! kubectl cluster-info >/dev/null 2>&1; then
        sudo bash /tmp/kube-start.sh
      fi

      # --- APPLY K8S MANIFESTS ---
    # Check if Calico is installed
  if ! kubectl get pods -l k8s-app=calico-node -n kube-system --no-headers 2>/dev/null | grep -q .; then
      echo "Installing Calico CNI..."
      kubectl apply -f /tmp/calico.yaml
      echo "Calico installation complete"
    else
      echo "Calico already installed, skipping"
    fi

    # Check if each required namespace exists
    needed_namespaces=(cicd build monitoring logging database application)
    namespaces_to_create=false
  
    for ns in "${needed_namespaces[@]}"; do
      if ! kubectl get namespace $ns &>/dev/null; then
        echo "Namespace $ns does not exist"
        namespaces_to_create=true
      fi
    done
  
    if [ "$namespaces_to_create" = true ]; then
      echo "Creating custom namespaces..."
      kubectl apply -f /tmp/namespaces.yaml
      echo "Custom namespaces creation complete"
    else
      echo "All required namespaces already exist, skipping"
    fi

    # Check if each resource quota exists
    quota_namespaces=(kube-system build cicd monitoring logging database application)
    quotas_to_create=false
  
    for ns in "${quota_namespaces[@]}"; do
      quota_name="${ns}-quota"
      if ! kubectl get resourcequota $quota_name -n $ns &>/dev/null; then
        echo "ResourceQuota $quota_name in namespace $ns does not exist"
        quotas_to_create=true
      fi
    done
  
    if [ "$quotas_to_create" = true ]; then
      echo "Creating resource quotas..."
      kubectl apply -f /tmp/namespaces-quotas.yaml
      echo "Resource quotas creation complete"
    else
      echo "All required resource quotas already exist, skipping"
    fi


      # Generate Docker secret: check if already generated
      if ! kubectl get secret regcred -n build >/dev/null 2>&1; then
        sudo bash /tmp/gen-docker-secret.sh
      fi

      # Generate Git secret: check if already generated
      if ! kubectl get secret git-credentials -n build >/dev/null 2>&1; then
        sudo bash /tmp/gen-git-secret.sh
      fi

      # Create kaniko config: check if already created
      if ! kubectl get configmap kaniko-build-config -n build >/dev/null 2>&1; then
        kubectl apply -f /tmp/kaniko-config.yaml
      fi

      # Create kaniko job: check if already created
       #if ! kubectl get job debug-kaniko -n build >/dev/null 2>&1; then
        kubectl apply -f /tmp/kaniko-job.yaml
       #fi


    SHELL

end
