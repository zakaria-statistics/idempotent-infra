#!/bin/bash
set -euxo pipefail


cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3: # NAT interface
      dhcp4: yes
      dhcp4-overrides:
        use-dns: false
        use-routes: true
      dhcp6-overrides:
        use-dns: false
      optional: true
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
    enp0s8: # Host-only interface
      dhcp4: no
      addresses:
        - 192.168.56.10/24
      routes:
        - to: 192.168.56.0/24
          via: 192.168.56.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

# Fix permissions for Netplan configuration files
sudo chmod 600 /etc/netplan/*.yaml

# Apply the Netplan configuration
sudo netplan apply
