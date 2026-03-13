#!/bin/bash
set -e
echo "[INFO] Starting entrypoint.sh (v3 with wgcf+wireproxy)"

mkdir -p /etc/warp-go
cd /etc/warp-go

if [ ! -f "warp.conf" ]; then
    echo "[INFO] Generating new WARP identity with wgcf..."
    wgcf register --accept-tos
    wgcf generate
    mv wgcf-profile.conf warp.conf
    
    echo "" >> warp.conf
    echo "[Socks5]" >> warp.conf
    echo "BindAddress = 0.0.0.0:1080" >> warp.conf
fi

if [ "${IPV6_PRIORITY}" = "true" ]; then
    sed -i 's/DNS = .*/DNS = 2606:4700:4700::1111, 2606:4700:4700::1001, 1.1.1.1, 1.0.0.1/g' warp.conf
else
    sed -i 's/DNS = .*/DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001/g' warp.conf
fi

echo "[INFO] Starting wireproxy with generated config..."
wireproxy -c /etc/warp-go/warp.conf > /var/log/wireproxy.log 2>&1 &
WP_PID=$!

sleep 3

echo "[INFO] Starting rotate_ip.sh in background..."
bash /rotate_ip.sh > /var/log/rotate.log 2>&1 &

echo "[INFO] Entering healthcheck loop..."
while true
do
  bash /healthcheck.sh
  tail -n 10 /var/log/wireproxy.log
  sleep 60
done
