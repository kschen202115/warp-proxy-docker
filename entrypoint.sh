#!/bin/bash
set -e
echo "[INFO] Starting entrypoint.sh (v3 with warp-go)"

mkdir -p /etc/warp-go
cd /etc/warp-go

if [ ! -f "warp.conf" ]; then
    echo "[INFO] Generating new WARP identity..."
    # 尝试用 warp-go 注册，如果失败，使用 fscarmen 的 API 代理
    if ! warp-go --register --export-wireguard=warp.conf > /dev/null 2>&1; then
        echo "[WARN] warp-go register failed, using API fallback..."
        API_RESP=$(curl -s --retry 5 https://warp.cloudflare.nyc.mn/?run=register || true)
        if echo "$API_RESP" | grep -q 'private_key'; then
            DEV_ID=$(echo "$API_RESP" | jq -r '.id')
            TOK=$(echo "$API_RESP" | jq -r '.token')
            PRIV=$(echo "$API_RESP" | jq -r '.private_key')
            cat > warp.conf << CONFE
[Interface]
PrivateKey = ${PRIV}
Address = 172.16.0.2/32
Address = 2606:4700:110:81c7:da82:f745:ceb3:6b64/128
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280
[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0
AllowedIPs = ::/0
Endpoint = engage.cloudflareclient.com:2408
CONFE
        else
            echo "[ERROR] API fallback also failed. Exiting."
            exit 1
        fi
    fi
    
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
