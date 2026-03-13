#!/bin/bash
set -x
echo "[INFO] Starting rotate_ip loop..."

while true
do
  sleep ${ROTATE_INTERVAL:-3600}

  echo "[INFO] Rotating WARP IP..."
  pkill wireproxy
  sleep 3
  
  mkdir -p /etc/wireguard
  cd /etc/wireguard
  rm -f wgcf-account.toml wgcf-profile.conf wireproxy.conf
  echo "[INFO] Requesting new identity..."
  wgcf register --accept-tos
  wgcf generate
  
  cat wgcf-profile.conf > wireproxy.conf
  echo "" >> wireproxy.conf
  echo "[Socks5]" >> wireproxy.conf
  echo "BindAddress = 0.0.0.0:1080" >> wireproxy.conf
  sed -i 's/DNS = .*/DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001/g' wireproxy.conf

  echo "[INFO] Restarting wireproxy..."
  wireproxy -c /etc/wireguard/wireproxy.conf > /var/log/wireproxy.log 2>&1 &

  echo "[INFO] IP rotated successfully."
done
