#!/bin/bash

# 创建 WireGuard 配置目录
mkdir -p /etc/wireguard

# 定义注册函数
function register_warp() {
    echo "[$(date)] 正在生成新的 WARP 账号..."
    rm -f /wgcf-account.toml /wgcf-profile.conf
    wgcf register --accept-tos
    wgcf generate
    # 优化 MTU 并确保 IPv6 路由开启
    sed -i "s/MTU = .*/MTU = 1280/" wgcf-profile.conf
    cp wgcf-profile.conf /etc/wireguard/wg0.conf
}

# 1. 执行初次注册
register_warp

# 2. 启动 WireGuard 隧道 (使用 wireguard-go)
echo "[$(date)] 正在启动 WireGuard 隧道..."
WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go wg-quick up wg0

# 3. 启动 SOCKS5 代理
echo "[$(date)] 正在启动 Dante SOCKS5 代理..."
sockd -D

# 4. 启动后台定时更换 IP 脚本
/rotate_ip.sh &

# 保持前台运行
echo "[$(date)] 服务已就绪！代理端口: 1080"
wait
