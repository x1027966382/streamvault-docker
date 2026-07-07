#!/bin/bash
# ===== StreamVault 一键部署脚本 =====
# 用法: bash setup.sh

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     StreamVault v2.0 一键部署       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ===== 1. 检测环境 =====
info "检测系统环境..."

# 检测 Docker
if ! command -v docker &>/dev/null; then
    err "未安装 Docker，请先安装"
    exit 1
fi
log "Docker 已安装: $(docker --version | head -1)"

# 检测 docker compose
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    err "未安装 docker compose"
    exit 1
fi
log "Docker Compose: $($COMPOSE_CMD version 2>/dev/null | head -1)"

# ===== 2. 配置部署目录 =====
DEPLOY_DIR="${STREAMVAULT_DIR:-/vol1/1000/docker/streamvault}"
info "部署目录: $DEPLOY_DIR"

read -p "使用默认目录? [Y/n]: " USE_DEFAULT
if [[ "$USE_DEFAULT" =~ ^[Nn]$ ]]; then
    read -p "输入部署目录: " DEPLOY_DIR
fi

# 创建目录结构
mkdir -p "$DEPLOY_DIR"/{app,app/db,app/log,app/cookies,app/resources,app/downloads/{douyin,bilibili,youtube,kuaishou,others},app/scripts,app/config,tmp,aria2}
log "目录结构已创建"

# ===== 3. 拷贝配置文件 =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 拷贝脚本到部署目录
for script in organize.sh nfo-gen.sh notify.sh cleanup.sh; do
    if [ -f "$SCRIPT_DIR/scripts/$script" ]; then
        cp "$SCRIPT_DIR/scripts/$script" "$DEPLOY_DIR/app/scripts/"
        chmod +x "$DEPLOY_DIR/app/scripts/$script"
        log "已拷贝 $script"
    fi
done

# 拷贝 Aria2 配置
if [ -f "$SCRIPT_DIR/aria2/aria2.conf" ]; then
    cp "$SCRIPT_DIR/aria2/aria2.conf" "$DEPLOY_DIR/aria2/"
    log "已拷贝 Aria2 配置"
fi

# ===== 4. 配置环境变量 =====
ENV_FILE="$DEPLOY_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << 'EOF'
# StreamVault 环境变量配置

# 时区
TZ=Asia/Shanghai

# 代理设置（如需外网访问）
# HTTP_PROXY=http://192.168.5.9:7890
# HTTPS_PROXY=http://192.168.5.9:7890

# 通知配置（可选）
# TELEGRAM_BOT_TOKEN=
# TELEGRAM_CHAT_ID=
# SERVERCHAN_KEY=
# PUSHPLUS_TOKEN=

# Aria2 RPC 密钥
ARIA2_RPC_SECRET=streamvault_secret

# Web 管理面板端口
WEB_PANEL_PORT=28082
EOF
    log "已创建 .env 配置文件"
    warn "请编辑 $ENV_FILE 配置通知和代理"
else
    log ".env 配置文件已存在"
fi

# ===== 5. 检测代理 =====
info "检测网络代理..."
detect_proxy() {
    for port in 7890 1080 8080 3128; do
        if curl -s --connect-timeout 2 "http://127.0.0.1:${port}" >/dev/null 2>&1; then
            echo "http://127.0.0.1:${port}"
            return 0
        fi
    done
    return 1
}

PROXY=$(detect_proxy)
if [ -n "$PROXY" ]; then
    log "检测到代理: $PROXY"
    # 更新 .env 文件中的代理设置
    sed -i "s|^# HTTP_PROXY=.*|HTTP_PROXY=$PROXY|" "$ENV_FILE"
    sed -i "s|^# HTTPS_PROXY=.*|HTTPS_PROXY=$PROXY|" "$ENV_FILE"
    log "已配置代理"
else
    warn "未检测到代理，部分功能可能受限"
fi

# ===== 6. 拉取镜像 =====
info "拉取最新镜像..."
docker pull ghcr.io/x1027966382/streamvault-docker:latest || {
    warn "镜像拉取失败，将使用本地缓存"
}

# ===== 7. 停止旧容器 =====
if docker ps -a --format '{{.Names}}' | grep -q "^streamvault$"; then
    info "停止旧容器..."
    docker stop streamvault 2>/dev/null || true
    docker rm streamvault 2>/dev/null || true
    log "旧容器已清理"
fi

# ===== 8. 启动服务 =====
info "启动服务..."
cd "$DEPLOY_DIR"
$COMPOSE_CMD -f "$SCRIPT_DIR/docker-compose.yml" up -d

# ===== 9. 等待启动 =====
info "等待服务启动..."
sleep 5

if docker ps --format '{{.Names}}' | grep -q "^streamvault$"; then
    log "✅ StreamVault 启动成功!"
    log ""
    log "📋 部署信息:"
    log "  Web 界面: http://$(hostname -I | awk '{print $1}'):28081"
    log "  默认账号: admin / 123456"
    log "  部署目录: $DEPLOY_DIR"
    log ""
    log "📖 下一步:"
    log "  1. 编辑配置: nano $ENV_FILE"
    log "  2. 配置 Cookie: 编辑 $DEPLOY_DIR/app/cookies/douyin.txt"
    log "  3. 查看日志: docker logs streamvault -f"
else
    err "启动失败，请检查日志: docker logs streamvault"
fi
