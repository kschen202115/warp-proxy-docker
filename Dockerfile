FROM alpine:latest

# 增加 iptables 和 ip6tables
RUN apk add --no-cache \
    wireguard-tools \
    wireguard-go \
    curl \
    dante-server \
    iproute2 \
    ca-certificates \
    bash \
    iptables

RUN WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url.*linux_amd64" | cut -d '"' -f 4) && \
    if [ -z "$WGCF_URL" ]; then WGCF_URL="https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_amd64"; fi && \
    curl -L "$WGCF_URL" -o /usr/local/bin/wgcf && \
    chmod +x /usr/local/bin/wgcf

COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
COPY sockd.conf /etc/sockd.conf

RUN chmod +x /entrypoint.sh /rotate_ip.sh

ENTRYPOINT ["/entrypoint.sh"]
