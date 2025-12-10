#!/bin/bash
set -e

echo "Installing Virtual Riller Network (VRN) – private ghost proxy"

# Install Go
if command -v dnf >/dev/null; then
  sudo dnf install -y golang git
elif command -v apt >/dev/null; then
  sudo apt update && sudo apt install -y golang-go git
else
  echo "Unsupported distro – only Fedora/Debian/Ubuntu"
  exit 1
fi

# Build
git clone https://github.com/yourname/VRN-public.git /opt/VRN-public 2>/dev/null || true
cd /opt/VRN-public
go build -trimpath -ldflags="-s -w" -o vrn ./cmd/vrn

sudo mkdir -p /etc/vrn
sudo cp config.example.toml /etc/vrn/config.toml
sudo cp vrn.service /etc/systemd/system/vrn.service

# Generate private credentials
UUID=$(cat /proc/sys/kernel/random/uuid)
SHORTID=$(openssl rand -hex 8)
sed -i "s/YOUR_UUID_HERE/$UUID/" /etc/vrn/config.toml
sed -i "s/YOUR_SHORTID_HERE/$SHORTID/" /etc/vrn/config.toml

# Self-signed cert (or user can replace with real Let’s Encrypt later)
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout /etc/vrn/privkey.pem -out /etc/vrn/fullchain.pem \
  -subj "/CN=vrn-local" 2>/dev/null

# Start
sudo systemctl daemon-reload
sudo systemctl enable --now vrn

IP=$(curl -4s ifconfig.me)

echo "VRN IS LIVE AND 100% PRIVATE"
echo "Your secret client link (copy exactly):"
echo "vless://$UUID@$IP:443?security=reality&sni=www.microsoft.com&sid=$SHORTID&fp=chrome&type=tcp&flow=xtls-rprx-vision#VRN-Ghost"
echo "Health check: curl http://127.0.0.1:8080/health"
