FROM alpine:latest

# 安装基础依赖
RUN apk add --no-cache wireguard-tools wireguard-go curl iproute2 ca-certificates bash

# 1. 下载最新版 wgcf
RUN WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url.*linux_amd64" | cut -d '"' -f 4) && \
    curl -L "$WGCF_URL" -o /usr/local/bin/wgcf && chmod +x /usr/local/bin/wgcf

# 2. 下载最新版 Gost
RUN GOST_URL=$(curl -s https://api.github.com/repos/ginuerzh/gost/releases/latest | grep "browser_download_url.*linux_amd64.tar.gz" | cut -d '"' -f 4) && \
    curl -L "$GOST_URL" | tar xz -C /usr/local/bin/ && chmod +x /usr/local/bin/gost

COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
RUN chmod +x /entrypoint.sh /rotate_ip.sh

ENTRYPOINT ["/entrypoint.sh"]
