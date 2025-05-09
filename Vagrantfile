Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.define "kube"
  
    config.vm.provider "virtualbox" do |vb|
      vb.name = "kube"
      vb.memory = "4096"
      vb.cpus = 8
    end
  
    # Optional: Increase disk size (requires vagrant-disksize plugin)
    config.disksize.size = "50GB"
  
    # Static private IP for Kubernetes
    config.vm.network "private_network", ip: "192.168.56.10"
  
    # Disable synced folder
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # Sync folders for scripts, manifests, docker files, and Jenkins Dockerfile
    config.vm.synced_folder "./scripts", "/home/vagrant/scripts"
    config.vm.synced_folder "./manifests", "/home/vagrant/manifests"
    config.vm.synced_folder "./docker", "/home/vagrant/docker"
    config.vm.synced_folder "./jenkins", "/home/vagrant/jenkins"
  
    # Add SSH public key (for Windows)
    config.vm.provision "file", source: "C:/Users/#{ENV['USERNAME']}/.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
    config.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      cat /tmp/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    SHELL
  
    # Upload provisioning scripts to /tmp only if they don't exist
    %w[
        configure-netplan.sh
        configure-dns.sh
        install-containerd.sh
        kube-preparation.sh
        kube-install.sh
        kube-start.sh
    ].each do |script|
        config.vm.provision "shell", inline: <<-SHELL
        if [ ! -f /tmp/#{script} ]; then
            cp /home/vagrant/scripts/#{script} /tmp/#{script}
        fi
        SHELL
    end

    # Upload Kubernetes manifests to /tmp only if they don't exist
    %w[
        calico.yaml
        namespaces.yaml
        namespaces-quotas.yaml
    ].each do |manifest|
        config.vm.provision "shell", inline: <<-SHELL
        if [ ! -f /tmp/#{manifest} ]; then
            cp /home/vagrant/manifests/#{manifest} /tmp/#{manifest}
        fi
        SHELL
    end

    # Upload Docker service manifests to /tmp only if they don't exist
    %w[
        docker-daemon.yaml
        docker-service.yaml
    ].each do |manifest|
        config.vm.provision "shell", inline: <<-SHELL
        if [ ! -f /tmp/#{manifest} ]; then
            cp /home/vagrant/docker/#{manifest} /tmp/#{manifest}
        fi
        SHELL
    end

    # Run provisioning steps
    config.vm.provision "shell", inline: <<-SHELL
      set -euxo pipefail
  
      # NETPLAN
      if ! grep -q '192.168.56.10' /etc/netplan/*.yaml; then
        sudo bash /tmp/configure-netplan.sh
      fi
  
      # DNS
      if ! grep -q '8.8.8.8' /etc/resolv.conf; then
        sudo bash /tmp/configure-dns.sh
      fi
  
      # CONTAINERD
      if ! command -v containerd >/dev/null 2>&1; then
        sudo bash /tmp/install-containerd.sh
      fi
  
      # KUBEADM
      if ! command -v kubeadm >/dev/null 2>&1; then
        sudo bash /tmp/kube-preparation.sh
        sudo bash /tmp/kube-install.sh
      fi
  
      # INIT K8S
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
    needed_namespaces=(cicd monitoring logging database application)
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
    quota_namespaces=(kube-system cicd monitoring logging database application)
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
  
      # --- APPLY DOCKER MANIFESTS ---
      if ! kubectl get pods -n kube-system | grep -q 'docker-daemon'; then
        kubectl apply -f /tmp/docker-daemon.yaml
      fi
  
      if ! kubectl get pods -n kube-system | grep -q 'docker-service'; then
        kubectl apply -f /tmp/docker-service.yaml
      fi
  
      echo ">> Provisioning complete. You may need to run 'vagrant reload' for docker group to apply."
    SHELL
  end
  