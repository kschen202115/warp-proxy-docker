#!/bin/bash
echo "[INFO] Running healthcheck..."
IP=$(curl -s --socks5 127.0.0.1:1080 --connect-timeout 5 https://api.ipify.org)

if [ -z "$IP" ]; then
   echo "[ERROR] Proxy dead or unreachable, restarting wireproxy..."
   pkill wireproxy
   mkdir -p /etc/wireguard
   cd /etc/wireguard
   wireproxy -c wireproxy.conf > /var/log/wireproxy.log 2>&1 &
else
   echo "[INFO] Healthcheck passed. Current IP: $IP"
fi
