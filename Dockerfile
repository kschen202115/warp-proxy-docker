FROM alpine:3.20

# 安装必要的依赖
RUN apk add --no-cache curl bash jq grep gawk sed

# 获取架构并下载对应的 warp-go (用来高效注册/换号) 和 wireproxy (用来代理和分流)
# 注意: fscarmen 是在 fscarmen/warp 的 main/warp-go 下提供了打包好的二进制文件
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        WARP_GO_URL="https://gitlab.com/fscarmen/warp/-/raw/main/warp-go/warp-go_1.0.8_linux_arm64.tar.gz"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_arm64.tar.gz"; \
    elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then \
        WARP_GO_URL="https://gitlab.com/fscarmen/warp/-/raw/main/warp-go/warp-go_1.0.8_linux_amd64.tar.gz"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_amd64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -sSL -o /tmp/warp-go.tar.gz $WARP_GO_URL && \
    tar -xzf /tmp/warp-go.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/warp-go && \
    rm /tmp/warp-go.tar.gz && \
    curl -sSL -o /tmp/wp.tar.gz $WP_URL && \
    tar -xzf /tmp/wp.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireproxy && \
    rm /tmp/wp.tar.gz

COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
COPY healthcheck.sh /healthcheck.sh

RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
