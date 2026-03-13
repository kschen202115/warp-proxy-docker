#!/bin/bash
echo "[INFO] Starting rotate_ip loop..."

IFS=',' read -r -a REGIONS_ARRAY <<< "${EXPECTED_REGIONS}"

while true
do
  MATCH=false
  while [ "$MATCH" = false ]; do
      echo "[INFO] Requesting new WARP identity..."
      pkill wireproxy
      sleep 3
      
      cd /etc/warp-go
      rm -f warp.conf
      
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
              echo "[ERROR] API fallback also failed. Retrying in 5s..."
              sleep 5
              continue
          fi
      fi
      
      echo "" >> warp.conf
      echo "[Socks5]" >> warp.conf
      echo "BindAddress = 0.0.0.0:1080" >> warp.conf
      
      if [ "${IPV6_PRIORITY}" = "true" ]; then
          sed -i 's/DNS = .*/DNS = 2606:4700:4700::1111, 2606:4700:4700::1001, 1.1.1.1, 1.0.0.1/g' warp.conf
      else
          sed -i 's/DNS = .*/DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001/g' warp.conf
      fi

      echo "[INFO] Starting wireproxy..."
      wireproxy -c /etc/warp-go/warp.conf > /var/log/wireproxy.log 2>&1 &
      sleep 10
      
      CURRENT_REGION=$(curl -s --socks5 127.0.0.1:1080 --connect-timeout 5 https://api.ip.sb/geoip | jq -r '.country_code')
      
      if [ -z "$CURRENT_REGION" ] || [ "$CURRENT_REGION" == "null" ]; then
          echo "[WARN] Could not determine region, retrying..."
          continue
      fi
      
      echo "[INFO] Current WARP Region is: ${CURRENT_REGION}"
      
      if [ ${#REGIONS_ARRAY[@]} -eq 0 ]; then
          echo "[INFO] No EXPECTED_REGIONS specified, keeping IP."
          MATCH=true
          break
      fi
      
      for REGION in "${REGIONS_ARRAY[@]}"; do
          if [ "${CURRENT_REGION}" == "${REGION}" ]; then
              MATCH=true
              break
          fi
      done
      
      if [ "$MATCH" = true ]; then
          echo "[INFO] Region matched (${CURRENT_REGION})! Keeping IP."
      else
          echo "[INFO] Region ${CURRENT_REGION} not in expected list (${EXPECTED_REGIONS}). Re-rolling in 5s..."
          sleep 5
      fi
  done
  
  echo "[INFO] IP rotated and region matched. Sleeping for ${ROTATE_INTERVAL:-3600} seconds..."
  sleep ${ROTATE_INTERVAL:-3600}
done
