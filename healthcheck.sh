#!/bin/bash

IP=$(curl -s --socks5 127.0.0.1:1080 https://ip.sb)

if [ -z "$IP" ]; then
   echo "warp dead, restarting"
   pkill warp-proxy
fi
