# StreamVault Docker 🎬

> 一键 Docker 部署 StreamVault 视频资源管理平台

## ⚠️ 前置条件

你需要先从 [StreamVault 原仓库](https://github.com/x1027966382/StreamVault) 下载 `spirit-0.0.1-SNAPSHOT.jar`，放到本目录下。

## 快速开始

```bash
# 1. 先把 spirit-0.0.1-SNAPSHOT.jar 放到当前目录
# 2. 构建并启动
cd streamvault-docker
docker compose up -d --build

# 3. 访问
# 地址: http://你的IP:28081
# 默认账号: admin
# 默认密码: 123456
```

## 目录说明

| 挂载路径 | 说明 |
|----------|------|
| `./data/resources/video` | 下载视频存储目录 |
| `./data/resources/cover` | 封面图片存储目录 |
| `./data/db` | 应用数据库（首次启动后自动生成） |
| `./data/tmp` | 临时文件 |

## 配置

- 编辑 `docker-compose.yml` 中的端口映射 `28081:28081` 来更改外部端口
- 环境变量可通过 `docker-compose.yml` 的 `environment` 添加

## 架构支持

- ✅ AMD64 (x86_64)
- ✅ ARM64 (Apple Silicon / 树莓派4+)

## 原仓库

[StreamVault](https://github.com/x1027966382/StreamVault) - 支持多平台的视频下载工具
