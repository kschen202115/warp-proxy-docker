FROM alpine:latest

# 1. 安装基础工具 (增加 grep 以便解析版本)
RUN apk add --no-cache \
    wireguard-tools curl dante-server iproute2 ca-certificates bash grep

# 2. 动态获取最新的 wgcf 并安装
RUN WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url.*linux_amd64" | cut -d '"' -f 4) && \
    echo "Downloading latest wgcf from: $WGCF_URL" && \
    curl -L "$WGCF_URL" -o /usr/local/bin/wgcf && \
    chmod +x /usr/local/bin/wgcf

# 3. 动态获取最新的 wireguard-go 并安装
RUN WG_GO_URL=$(curl -s https://api.github.com/repos/tailscale/wireguard-go/releases/latest | grep "browser_download_url.*linux-amd64.tar.gz" | cut -d '"' -f 4) && \
    echo "Downloading latest wireguard-go from: $WG_GO_URL" && \
    curl -L "$WG_GO_URL" | tar xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireguard-go

# 4. 拷贝脚本和配置
COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
COPY sockd.conf /etc/sockd.conf

RUN chmod +x /entrypoint.sh /rotate_ip.sh

ENTRYPOINT ["/entrypoint.sh"]
