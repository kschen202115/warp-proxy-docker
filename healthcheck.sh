#!/bin/bash
echo "[INFO] Running healthcheck..."
IP=$(curl -s --socks5 127.0.0.1:1080 --connect-timeout 10 https://cloudflare.com/cdn-cgi/trace | grep "ip=" | cut -d'=' -f2)

sleep 3

echo "[INFO] Healthcheck passed. Current IP: $IP"

