# WARP Proxy Docker

一个基于 Docker 的 Cloudflare WARP 代理服务，提供 SOCKS5 代理功能，并支持定期自动更换 IP。

**当前仓库提供两个版本供选择，请根据您的网络需求进行部署：**

1. **[默认版本] Wireproxy 轻量版**：位于主目录。无需特权模式，CPU 和内存占用极低（几乎为0），连接极度稳定。**缺点是仅支持 IPv4 代理出口**。
2. **[备选版本] 官方 warp-svc 完整版**：位于 `warp-svc/` 目录。使用官方守护进程，**支持完整的 6in4（即通过代理访问纯 IPv6 网站）**。缺点是需要特权模式（`privileged: true`），且守护进程会导致较高的 CPU 占用。

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📋 目录

- [功能特性](#功能特性)
- [前置要求](#前置要求)
- [快速开始 (Wireproxy 轻量版)](#快速开始)
- [快速开始 (warp-svc IPv6版)](#ipv6支持版本)
- [配置说明](#配置说明)
- [使用方法](#使用方法)

## 🌟 功能特性

- ✅ **SOCKS5 代理服务** - 提供稳定的 SOCKS5 代理
- ✅ **自动更换 IP** - 支持定时重置账号更换 IP，避免被限制
- ✅ **断线自愈** - 增加网络健康检查，节点无响应自动重启恢复
- ✅ **极低占用** - (默认版) 放弃官方守护进程，改用 wireproxy，资源消耗极低

## 📦 前置要求

- Docker（版本 20.10+）
- Docker Compose（版本 1.29+）

## 🚀 快速开始 (默认 Wireproxy 版)

推荐绝大多数只需突破网络封锁或进行普通爬虫任务的用户使用此版本。

### 1. 克隆项目

```bash
git clone https://github.com/kschen202115/warp-proxy-docker.git
cd warp-proxy-docker
```

### 2. 启动服务

```bash
docker compose up -d
```

### 3. 验证服务

```bash
# 测试 SOCKS5 代理（需要安装 curl）
curl -x socks5h://127.0.0.1:1080 https://api.ipify.org
```

---

## 🌐 IPv6 支持版本 (warp-svc 官方内核版)

如果您**必须**通过代理访问纯 IPv6 的网站（如 `ipv6.icanhazip.com`），请部署 `warp-svc` 目录下的版本。

```bash
cd warp-svc
docker compose up -d
```
> **注意**：该版本需要 `privileged: true` 及 `NET_ADMIN` 权限，并且会产生较高的 CPU 占用。详情请查看 `warp-svc/README.md`。

---

## ⚙️ 配置说明

编辑 `docker-compose.yml` 文件中的环境变量可以调整运行参数：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `ROTATE_INTERVAL` | 3600 | IP 定时更换时间间隔（秒），默认 1 小时 |

### 修改配置示例

```yaml
environment:
  - ROTATE_INTERVAL=1800    # 改为 30 分钟自动更换一次
```

然后重启服务：

```bash
docker compose down && docker compose up -d
```

## 💻 使用方法

### 命令行测试

```bash
# 测试 SOCKS5 连接
curl -x socks5h://127.0.0.1:1080 https://api.ipify.org
```

### Python 使用

```python
import requests

def get_ip_via_warp():
    socks_proxy = 'socks5h://127.0.0.1:1080'
    proxies = {
        'http': socks_proxy,
        'https': socks_proxy,
    }
    
    response = requests.get('https://api.ipify.org?format=json', proxies=proxies)
    return response.json()

print(get_ip_via_warp())
```

### Node.js 使用

```javascript
const axios = require('axios');
const { SocksProxyAgent } = require('socks-proxy-agent');

const agent = new SocksProxyAgent('socks5h://127.0.0.1:1080');

axios.get('https://api.ipify.org?format=json', { httpsAgent: agent })
  .then(res => console.log(res.data));
```

## ⚠️ 注意事项

1. **Cloudflare ToS** - 使用本项目需遵守 Cloudflare WARP 服务条款。
2. **连接稳定性** - 由于免费 WARP 节点可能遭到网络干预，脚本内置了断线检测与重连功能。如果日志中频繁出现 `Proxy dead`，属正常自愈行为。

## 📝 许可证

MIT License - 详见 LICENSE 文件
