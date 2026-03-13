#!/bin/bash
mkdir -p /etc/wireguard

function register_warp() {
    echo "[$(date)] 正在注册 WARP 账号..."
    rm -f /wgcf-account.toml /wgcf-profile.conf
    wgcf register --accept-tos
    wgcf generate
    
    # 1. 彻底删除 DNS 行
    sed -i '/DNS/d' wgcf-profile.conf
    # 2. 设置 MTU
    sed -i "s/MTU = .*/MTU = 1280/" wgcf-profile.conf
    # 3. 启用 PostUp 确保路由生效，但不使用 Table = off
    # 我们让 wg-quick 正常工作，通过安装 ip6tables 解决它的报错
    
    cp wgcf-profile.conf /etc/wireguard/wg0.conf
}

register_warp

echo "[$(date)] 启动 WireGuard 隧道..."
# 环境变量：让 wg-quick 忽略 resolvconf 错误
export WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go
wg-quick up wg0

# 验证网卡和 IP
ip addr show wg0

echo "[$(date)] 启动 Dante SOCKS5 代理..."
sockd -D

/rotate_ip.sh &
wait
