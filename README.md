# StreamVault Docker

[![Build & Push to GHCR](https://github.com/x1027966382/streamvault-docker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/x1027966382/streamvault-docker/actions/workflows/docker-build.yml)

StreamVault 视频下载平台的独立 Docker 部署镜像。

> 基于 [StreamVault](https://github.com/x1027966382/StreamVault) 项目构建。

## 🚀 快速部署

```bash
docker compose up -d
```

访问: http://localhost:28081

默认账号: `admin` / `123456`

## 📦 镜像来源

| 来源 | 地址 |
|------|------|
| GHCR (推荐) | `ghcr.io/x1027966382/streamvault:latest` |

## ⚙️ 配置代理（可选）

如需代理访问外网（如抖音等），编辑 `docker-compose.yml` 取消注释：

```yaml
environment:
  - http_proxy=http://192.168.5.9:7890
  - https_proxy=http://192.168.5.9:7890
```

## 🏗️ 本地构建（不使用 GHCR）

```bash
# 1. 下载 JAR（如尚未包含在仓库中）
curl -L -o spirit-0.0.1-SNAPSHOT.jar \
  "https://raw.githubusercontent.com/x1027966382/StreamVault/main/backstage/src/main/docker/buildx/spirit-0.0.1-SNAPSHOT.jar"

# 2. 构建镜像
docker build -t streamvault:latest .

# 3. 运行
docker run -d -p 28081:28081 --name streamvault streamvault:latest
```

## 📁 目录结构

```
streamvault-docker/
├── Dockerfile
├── docker-compose.yml
├── .github/workflows/
│   └── docker-build.yml    # GHCR 自动构建
├── db/
│   └── spirit.db           # SQLite 数据库
├── script/
│   └── douyin.py           # 抖音下载脚本
├── static/                 # 前端静态资源（需自行放入）
└── spirit-0.0.1-SNAPSHOT.jar  # 后端 JAR
```

## 📝 注意事项

- `static/` 目录需要从原 StreamVault 项目获取前端构建产物
- `spirit-0.0.1-SNAPSHOT.jar` 需要从原仓库下载（约60MB）
- 推送到 `main` 分支后，GitHub Actions 会自动构建并推送到 GHCR
