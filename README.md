# 🎬 StreamVault v2.0

> 视频下载平台 — 一键部署 + Aria2 加速 + 智能管理

[![Docker](https://img.shields.io/badge/Docker-ghcr.io-blue)](https://github.com/x1027966382/streamvault-docker/pkgs/container/streamvault-docker)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## ✨ 特性

### 🔧 基础优化
- **Debian 基础镜像** — 告别 Alpine 兼容性问题，Python 包安装秒完成
- **多阶段构建** — 编译环境与运行环境分离，镜像更小更安全
- **健康检查** — 自动检测服务状态，异常自动重启
- **日志轮转** — 防止日志文件撑爆磁盘

### 🚀 创新功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | **一键部署** | `bash setup.sh` 搞定所有配置 |
| 2 | **Aria2 下载后端** | 多线程、断点续传、限速、RPC 控制 |
| 3 | **智能目录结构** | 自动按 `平台/创作者/日期` 整理 |
| 4 | **Emby/Jellyfin 刮削** | 自动生成 NFO 元数据 + 封面 |
| 5 | **下载完成通知** | 支持 Telegram/Server酱/PushPlus/钉钉 |
| 6 | **Web 管理面板** | 下载任务管理 + 统计 + 配置 |
| 7 | **代理自动配置** | 检测 NAS 代理环境，自动配置容器网络 |
| 8 | **定时清理** | 自动清理过期临时文件、重复下载、过期日志 |

## 📦 快速开始

### 方式一：一键部署（推荐）

```bash
# 克隆仓库
git clone https://github.com/x1027966382/streamvault-docker.git
cd streamvault-docker

# 一键部署
bash setup.sh
```

### 方式二：手动部署

```bash
# 1. 创建目录
mkdir -p /vol1/1000/docker/streamvault/{app,app/{db,log,cookies,resources,downloads,scripts,config},tmp,aria2}

# 2. 复制配置文件
cp .env.example /vol1/1000/docker/streamvault/.env

# 3. 启动服务
docker compose up -d
```

### 方式三：直接拉取镜像

```bash
docker pull ghcr.io/x1027966382/streamvault-docker:latest

docker run -d \
  --name streamvault \
  -p 28081:28081 \
  -v /vol1/1000/docker/streamvault/app:/app \
  -v /vol1/1000/docker/streamvault/tmp:/tmp \
  --restart unless-stopped \
  ghcr.io/x1027966382/streamvault-docker:latest
```

## 🌐 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| StreamVault | `http://NAS_IP:28081` | 主应用，默认账号 `admin / 123456` |
| Web 管理面板 | `http://NAS_IP:28082` | 下载管理 + 统计 |
| Aria2 RPC | `http://NAS_IP:6800` | RPC 接口（用于外部工具） |

## 📁 目录结构

```
/vol1/1000/docker/streamvault/
├── app/
│   ├── db/              # 数据库
│   ├── log/             # 日志
│   ├── cookies/         # Cookie 文件
│   ├── resources/       # 下载资源
│   ├── downloads/       # 下载文件
│   │   ├── douyin/      # 抖音
│   │   ├── bilibili/    # B站
│   │   ├── youtube/     # YouTube
│   │   ├── kuaishou/    # 快手
│   │   └── others/      # 其他
│   ├── scripts/         # 脚本
│   └── config/          # 配置
├── tmp/                 # 临时文件
├── aria2/               # Aria2 配置
└── .env                 # 环境变量
```

## ⚙️ 配置说明

### 环境变量（.env）

```bash
# 部署目录
STREAMVAULT_DIR=/vol1/1000/docker/streamvault

# 代理设置（如需外网访问）
HTTP_PROXY=http://192.168.5.9:7890
HTTPS_PROXY=http://192.168.5.9:7890

# 通知配置
TELEGRAM_BOT_TOKEN=your_token
TELEGRAM_CHAT_ID=your_chat_id
SERVERCHAN_KEY=your_key
PUSHPLUS_TOKEN=your_token
DINGTALK_WEBHOOK=your_webhook

# Aria2 RPC 密钥
ARIA2_RPC_SECRET=your_secret

# Web 面板端口
WEB_PANEL_PORT=28082
```

### Cookie 配置

1. 登录 StreamVault Web 界面
2. 进入「系统设置」→「Cookie 配置」
3. 填写抖音 Cookie

Cookie 文件位置：`/vol1/1000/docker/streamvault/app/cookies/douyin.txt`

## 🔧 脚本说明

### 智能整理（organize.sh）

自动按 `平台/创作者/日期` 整理下载文件：

```bash
# 手动执行
docker exec streamvault bash /app/scripts/organize.sh

# 或通过 Web 面板执行
```

### NFO 刮削（nfo-gen.sh）

为视频生成 Emby/Jellyfin 兼容的 NFO 元数据：

```bash
docker exec streamvault bash /app/scripts/nfo-gen.sh
```

### 下载通知（notify.sh）

测试通知推送：

```bash
docker exec streamvault bash /app/scripts/notify.sh "测试标题" "测试内容"
```

### 定时清理（cleanup.sh）

自动清理过期文件，每天凌晨 3 点执行：

```bash
# 手动执行
docker exec streamvault bash /app/scripts/cleanup.sh
```

## 🐳 Docker Compose 服务

```bash
# 启动所有服务
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f

# 停止所有服务
docker compose down

# 重启所有服务
docker compose restart
```

## 📊 Web 管理面板

访问 `http://NAS_IP:28082`，功能包括：

- **📊 总览** — 下载文件统计、平台分布、最近下载
- **📁 文件管理** — 目录浏览、一键整理、NFO 生成
- **📋 任务队列** — 下载任务管理
- **⚙️ 配置** — 通知配置、代理设置
- **📝 日志** — 系统日志查看

## ❓ 常见问题

### Q: 如何配置代理？

1. 编辑 `.env` 文件，取消代理注释：
```bash
HTTP_PROXY=http://192.168.5.9:7890
HTTPS_PROXY=http://192.168.5.9:7890
```

2. 重启服务：
```bash
docker compose restart streamvault
```

### Q: 如何查看日志？

```bash
# 实时日志
docker logs streamvault -f

# 最近100行
docker logs streamvault --tail 100
```

### Q: 如何更新镜像？

```bash
# 拉取最新镜像
docker pull ghcr.io/x1027966382/streamvault-docker:latest

# 重启服务
docker compose restart streamvault
```

### Q: Aria2 如何使用？

Aria2 RPC 地址：`http://NAS_IP:6800/jsonrpc`

密钥：在 `.env` 中配置的 `ARIA2_RPC_SECRET`

可搭配 AriaNg 等前端使用。

## 📄 License

MIT License

## 🙏 致谢

- [StreamVault](https://github.com/x1027966382/StreamVault) — 原版项目
- [aria2-pro](https://github.com/P3TERX/aria2-docker) — Aria2 Docker 镜像
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — 视频下载工具
- [f2](https://github.com/Johnserf-Seed/f2) — 抖音数据采集
