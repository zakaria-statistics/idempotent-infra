#!/bin/bash
set -euxo pipefail

# Update & Install Tools
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release \
  software-properties-common jq conntrack socat ebtables ethtool net-tools \
  ipvsadm ipset nftables

# Disable Swap
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo rm -f /swap.img

cat <<EOF | sudo tee /etc/systemd/system/disable-swap.service
[Unit]
Description=Disable Swap
DefaultDependencies=no
Before=swap.target

[Service]
Type=oneshot
ExecStart=/sbin/swapoff -a
ExecStop=/sbin/swapoff -a
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable disable-swap.service
sudo systemctl start disable-swap.service

# Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe nf_conntrack

# Ensure required cgroups are enabled
if ! grep -q "cgroup" /proc/filesystems; then
  echo "Required cgroups are not enabled. Ensure your system supports cgroups and they are properly configured."
  exit 1
fi

# Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
fs.file-max = 65535
kernel.pid_max = 65536

net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
EOF

sudo sysctl --system
