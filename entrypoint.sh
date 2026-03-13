#!/bin/bash

# 开启调试输出
set -x
echo "[INFO] Starting entrypoint.sh"

# 确保目录存在
mkdir -p /etc/wireguard
cd /etc/wireguard

# 初始化 WARP 账号并生成 WireGuard 配置文件
if [ ! -f "wgcf-profile.conf" ]; then
    echo "[INFO] Generating new WARP identity..."
    wgcf register --accept-tos
    wgcf generate
fi

echo "[INFO] Configuring wireproxy..."
cat wgcf-profile.conf > wireproxy.conf
echo "" >> wireproxy.conf
echo "[Socks5]" >> wireproxy.conf
echo "BindAddress = 0.0.0.0:1080" >> wireproxy.conf
sed -i 's/DNS = .*/DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001/g' wireproxy.conf

echo "[INFO] Starting wireproxy in background..."
wireproxy -c /etc/wireguard/wireproxy.conf > /var/log/wireproxy.log 2>&1 &
WP_PID=$!

sleep 5

echo "[INFO] Starting rotate_ip.sh in background..."
bash /rotate_ip.sh > /var/log/rotate.log 2>&1 &

echo "[INFO] Entering healthcheck loop..."
while true
do
  bash /healthcheck.sh
  # 将 wireproxy 的日志持续输出到终端，防止静默卡死
  tail -n 10 /var/log/wireproxy.log
  sleep 60
done
