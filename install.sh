#!/bin/bash
set -e
echo "Realer Virtual Network (RVN) — deploying your private ghost node"

# Install dependencies
if command -v dnf >/dev/null; then sudo dnf install -y golang git; fi
if command -v apt >/dev/null; then sudo apt update && sudo apt install -y golang-go git; fi

# Clone & build
git clone https://github.com/RealerNetwork/RVN.git /opt/RVN 2>/dev/null || (cd /opt/RVN; git pull)
cd /opt/RVN
go build -trimpath -ldflags="-s -w" -o rvn ./cmd/rvn

# Config & paths
sudo mkdir -p /etc/rvn
sudo cp config.example.toml /etc/rvn/config.toml
sudo cp rvn.service /etc/systemd/system/rvn.service

# Generate unique private credentials
UUID=$(cat /proc/sys/kernel/random/uuid)
SHORTID=$(openssl rand -hex 8)
sed -i "s/YOUR_UUID_HERE/$UUID/" /etc/rvn/config.toml
sed -i "s/YOUR_SHORTID_HERE/$SHORTID/" /etc/rvn/config.toml

# Self-signed TLS cert (user can replace with real Let’s Encrypt later)
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout /etc/rvn/privkey.pem -out /etc/rvn/fullchain.pem \
  -subj "/CN=realer.local" 2>/dev/null

# Start daemon
sudo systemctl daemon-reload
sudo systemctl enable --now rvn

IP=$(curl -4s https://ifconfig.me)

echo "===================================================="
echo "Realer Virtual Network (RVN) is LIVE"
echo "You are now completely untraceable"
echo ""
echo "Your private client link (copy exactly):"
echo "vless://$UUID@$IP:443?security=reality&sni=www.microsoft.com&sid=$SHORTID&fp=chrome&type=tcp&flow=xtls-rprx-vision#Realer-Virtual-Network"
echo ""
echo "Health check: curl http://127.0.0.1:8080/health"
echo "===================================================="
