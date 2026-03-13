FROM alpine:3.20

RUN apk add --no-cache curl bash jq grep gawk sed

# 同时下载 wgcf (最靠谱的注册工具) 和 wireproxy
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        WGCF_URL="https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_arm64"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_arm64.tar.gz"; \
    elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then \
        WGCF_URL="https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_amd64"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_amd64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L -o /usr/local/bin/wgcf $WGCF_URL && \
    chmod +x /usr/local/bin/wgcf && \
    curl -sSL -o /tmp/wp.tar.gz $WP_URL && \
    tar -xzf /tmp/wp.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireproxy && \
    rm /tmp/wp.tar.gz

COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
COPY healthcheck.sh /healthcheck.sh

RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
