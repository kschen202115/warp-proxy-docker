#!/bin/bash
mkdir -p /etc/wireguard

function register_warp() {
    echo "[$(date)] 正在注册 WARP 账号..."
    rm -f /wgcf-account.toml /wgcf-profile.conf
    wgcf register --accept-tos
    wgcf generate
    
    # 1. 删除 DNS
    sed -i '/DNS/d' wgcf-profile.conf
    # 2. 设置 MTU
    sed -i "s/MTU = .*/MTU = 1280/" wgcf-profile.conf
    # 3. 核心修复：禁用自动路由表和防火墙规则，防止报错删除网卡
    sed -i '/\[Interface\]/a Table = off' wgcf-profile.conf
    
    cp wgcf-profile.conf /etc/wireguard/wg0.conf
}

register_warp

echo "[$(date)] 启动 WireGuard 隧道..."
WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go wg-quick up wg0

# 检查网卡是否成功
max_retry=10
counter=0
while ! ip link show wg0 > /dev/null 2>&1; do
    sleep 1
    ((counter++))
    if [ $counter -ge $max_retry ]; then
        echo "错误：wg0 网卡未能在 10 秒内启动！"
        exit 1
    fi
done

echo "[$(date)] 启动 Dante SOCKS5 代理..."
sockd -D

/rotate_ip.sh &
wait
