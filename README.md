# StreamVault Docker 🎬

> 一键 Docker 部署 StreamVault 视频资源管理平台

## 快速开始

```bash
cd streamvault-docker
docker compose up -d --build
```

访问 `http://你的IP:5999`

## 目录说明

| 挂载路径 | 说明 |
|----------|------|
| `./data/resources/video` | 下载视频存储目录 |
| `./data/resources/cover` | 封面图片存储目录 |
| `./data/db` | 应用数据库 |
| `./data/tmp` | 临时文件 |

## 配置

编辑 `docker-compose.yml` 中的端口映射 `5999:5999` 来更改外部端口。

## 原仓库

[StreamVault](https://github.com/x1027966382/StreamVault)
