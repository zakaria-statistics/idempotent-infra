Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.define "kube" # Set the VM name with unique timestamp

    config.vm.provider "virtualbox" do |vb|
        vb.name = "kube" # Explicitly set the VM name with unique timestamp
        vb.memory = "8192"
        vb.cpus = 12
    end

    # Configure disk size using vagrant-disksize plugin
    config.disksize.size = "50GB"

    # NAT interface (default)
    # config.vm.network "public_network", bridge: "enp0s3", use_dhcp_assigned_default_route: true

    # Host-only network (static IP for Kubernetes)
    config.vm.network "private_network", ip: "192.168.56.10"

    # Sync folder disabled
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # Add SSH key for logging into the VM (Windows-compatible path)
    config.vm.provision "file", source: "C:/Users/#{ENV['USERNAME']}/.ssh/id_rsa.pub", destination: "/tmp/authorized_keys"
    config.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      mv /tmp/authorized_keys /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    SHELL
end
