Vagrant.configure("2") do |config|

  BOX_NAME = "ubuntu/jammy64"
  ANSIBLE_SYNC_HOST = "./ansible"
  ANSIBLE_SYNC_GUEST = "/home/vagrant/ansible"

  # === Ansible control VM ===
  config.vm.define "ansible" do |ansible|
    ansible.vm.box = BOX_NAME
    ansible.vm.hostname = "ansible"

    ansible.vm.provider "virtualbox" do |vb|
      vb.name = "ansible"
      vb.memory = 2048
      vb.cpus = 2
    end

    ansible.vm.network "private_network", ip: "192.168.56.20"

    # Sync only the ansible folder (playbooks, scripts)
    ansible.vm.synced_folder ANSIBLE_SYNC_HOST, ANSIBLE_SYNC_GUEST

    ansible.vm.provision "file", source: "#{ENV['HOME']}/.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
    ansible.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      cat /tmp/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
      rm /tmp/id_rsa.pub
    SHELL
  end

  # === Kubernetes cluster VM ===
  config.vm.define "kube" do |kube|
    kube.vm.box = BOX_NAME
    kube.vm.hostname = "kube"

    kube.vm.provider "virtualbox" do |vb|
      vb.name = "kube"
      vb.memory = 8192
      vb.cpus = 12
      if Vagrant.has_plugin?("vagrant-disksize")
        kube.disksize.size = "50GB"
      end
    end

    kube.vm.network "private_network", ip: "192.168.56.10"

     # Sync folder disabled
    config.vm.synced_folder ".", "/vagrant", disabled: true

    kube.vm.provision "file", source: "#{ENV['HOME']}/.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
    kube.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      cat /tmp/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
      rm /tmp/id_rsa.pub
    SHELL
  end

end
