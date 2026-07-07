# StreamVault Docker

[![Build & Push to GHCR](https://github.com/x1027966382/streamvault-docker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/x1027966382/streamvault-docker/actions/workflows/docker-build.yml)

StreamVault 视频下载平台的独立 Docker 部署镜像。

> 基于 [StreamVault](https://github.com/x1027966382/StreamVault) 项目构建。

## 🚀 快速部署

```bash
# 创建数据目录
mkdir -p /vol1/docker/streamvault/{app,tmp}

# 启动
docker run -d \
  --name streamvault \
  -p 28081:28081 \
  -v /vol1/docker/streamvault/app:/app \
  -v /vol1/docker/streamvault/tmp:/tmp \
  --restart unless-stopped \
  ghcr.io/x1027966382/streamvault:latest
```

访问: http://localhost:28081/admin/login

默认账号: `admin` / `123456`

## 📦 镜像来源

| 来源 | 地址 |
|------|------|
| GHCR (推荐) | `ghcr.io/x1027966382/streamvault:latest` |
| Docker Hub (原作者) | `qingfeng2336/stream-vault` |

## ⚙️ 配置代理（可选）

如需代理访问外网（如抖音、YouTube 等），加上 `-e` 参数：

```bash
docker run -d \
  --name streamvault \
  -p 28081:28081 \
  -v /vol1/docker/streamvault/app:/app \
  -v /vol1/docker/streamvault/tmp:/tmp \
  -e http_proxy=http://192.168.5.9:7890 \
  -e https_proxy=http://192.168.5.9:7890 \
  --restart unless-stopped \
  ghcr.io/x1027966382/streamvault:latest
```

## 📂 目录映射

| 容器内路径 | 说明 |
|-----------|------|
| `/app` | 应用主目录（含配置、资源） |
| `/app/resources/video` | 视频下载存储 |
| `/app/resources/cover` | 封面存储 |
| `/app/db` | SQLite 数据库 |
| `/tmp` | 临时文件 |

## 🐳 Docker Compose 部署

```bash
# 创建 docker-compose.yml（如上），然后
docker compose up -d
```

## 🏗️ 本地构建

```bash
# 下载 JAR
curl -L -o spirit-0.0.1-SNAPSHOT.jar \
  "https://raw.githubusercontent.com/x1027966382/StreamVault/main/backstage/src/main/docker/buildx/spirit-0.0.1-SNAPSHOT.jar"

# 构建镜像
docker build -t streamvault:latest .

# 运行
docker run -d \
  --name streamvault \
  -p 28081:28081 \
  -v /vol1/docker/streamvault/app:/app \
  -v /vol1/docker/streamvault/tmp:/tmp \
  streamvault:latest
```

## 📦 包含内容

- Java 8 运行环境
- Python3 + f2（抖音下载脚本）
- yt-dlp（视频下载工具）
- ffmpeg（音视频处理）
- SQLite 数据库 + 抖音下载脚本
