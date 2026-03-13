#!/bin/bash

# 健康检查：尝试通过代理访问外部 IP，如果失败则杀掉代理进程使其重启
IP=$(curl -s --socks5 127.0.0.1:1080 --connect-timeout 5 https://api.ipify.org)

if [ -z "$IP" ]; then
   echo "Proxy dead or unreachable, restarting wireproxy..."
   pkill wireproxy
   mkdir -p /etc/wireguard
   cd /etc/wireguard
   wireproxy -c wireproxy.conf &
fi
