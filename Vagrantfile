Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.define "kube" 

    config.vm.provider "virtualbox" do |vb|
        vb.name = "kube" 
        vb.memory = "8192"
        vb.cpus = 12
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
    SHELL
end
