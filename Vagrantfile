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

    # IMPORTANT: If you use a custom SSH private key with config.ssh.private_key_path,
    # do NOT place the .pub public key file in the same directory, as it may confuse Vagrant's SSH handling.
    # See: https://stackoverflow.com/a/69252601

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
    
    # Make the scripts executable
    config.vm.provision "shell", inline: <<-SHELL
      set -euxo pipefail
      sudo bash /tmp/configure-netplan.sh
      sudo bash /tmp/configure-dns.sh
    SHELL
end
