#!/bin/bash
while true; do
    sleep ${RESTART_INTERVAL:-3600}
    echo "[$(date)] 开始定时更换 IP..."
    wg-quick down wg0
    rm -f /wgcf-account.toml /wgcf-profile.conf
    wgcf register --accept-tos && wgcf generate
    
    sed -i '/DNS/d' wgcf-profile.conf
    sed -i "s/MTU = .*/MTU = 1280/" wgcf-profile.conf
    sed -i '/\[Interface\]/a Table = off' wgcf-profile.conf
    
    cp wgcf-profile.conf /etc/wireguard/wg0.conf
    WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go wg-quick up wg0
    pkill sockd && sockd -D
    
    echo "[$(date)] 更换完成。"
done
