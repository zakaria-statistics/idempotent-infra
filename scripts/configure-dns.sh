
sudo systemctl stop systemd-resolved || true
sudo systemctl disable systemd-resolved || true
sudo rm -f /etc/resolv.conf

cat <<EOF | sudo tee /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
options timeout:2 attempts:3 rotate single-request-reopen
EOF

sudo chattr +i /etc/resolv.conf
