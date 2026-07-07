#!/bin/bash

# ===== StreamVault v2.0 启动脚本 =====

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[streamvault]${NC} $1"; }
warn() { echo -e "${YELLOW}[streamvault]${NC} $1"; }
err() { echo -e "${RED}[streamvault]${NC} $1"; }

log "🚀 StreamVault v2.0 启动中..."

# ===== 1. 数据库初始化 =====
if [ ! -f /app/db/spirit.db ]; then
    log "首次启动，初始化数据库..."
    mkdir -p /app/db
    cp /home/app/db/* /app/db/
    log "✅ 数据库已初始化"
else
    log "数据库已存在，跳过初始化"
fi

# ===== 2. 创建必要目录 =====
log "创建必要目录..."
mkdir -p /app/{resources,log,cookies,downloads,downloads/douyin,downloads/bilibili,downloads/youtube,downloads/kuaishou,downloads/others,scripts,config}

# ===== 3. 代理自动配置 =====
log "检测网络环境..."
PROXY=""

# 检测环境变量（优先）
if [ -n "$HTTP_PROXY" ]; then
    PROXY="$HTTP_PROXY"
elif [ -n "$HTTPS_PROXY" ]; then
    PROXY="$HTTPS_PROXY"
fi

# 检测常见代理端口
if [ -z "$PROXY" ]; then
    for port in 7890 1080 8080 3128; do
        if curl -s --connect-timeout 1 --max-time 2 "http://127.0.0.1:${port}" >/dev/null 2>&1; then
            PROXY="http://127.0.0.1:${port}"
            break
        fi
    done 2>/dev/null || true
fi

if [ -n "$PROXY" ]; then
    log "✅ 检测到代理: $PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    export ALL_PROXY="$PROXY"
    echo "PROXY=$PROXY" > /app/config/proxy.env 2>/dev/null || true
else
    warn "⚠️ 未检测到代理，部分功能可能受限"
    echo "PROXY=" > /app/config/proxy.env 2>/dev/null || true
fi

# ===== 4. 验证 Python 环境 =====
log "验证 Python 环境..."
if [ -f /opt/venv/bin/python3 ]; then
    PY_VERSION=$(/opt/venv/bin/python3 --version 2>&1)
    log "✅ Python: $PY_VERSION"
else
    warn "⚠️ Python 虚拟环境不存在"
fi

if [ -f /opt/venv/bin/python3 ]; then
    /opt/venv/bin/python3 -c "import f2" 2>/dev/null && \
        log "✅ f2 已安装" || \
        warn "⚠️ f2 导入失败"
fi

# ===== 5. 检查 Cookie 文件 =====
if [ -f /app/cookies/douyin.txt ]; then
    COOKIE_SIZE=$(wc -c < /app/cookies/douyin.txt 2>/dev/null || echo 0)
    log "✅ 抖音 Cookie 文件存在 (${COOKIE_SIZE} bytes)"
else
    warn "⚠️ 抖音 Cookie 文件不存在，请在后台配置"
fi

# ===== 6. 确保脚本可执行 =====
log "设置脚本权限..."
chmod +x /home/app/script/*.py 2>/dev/null || true
chmod +x /app/scripts/*.sh 2>/dev/null || true

# ===== 7. 启动 StreamVault =====
log "启动 StreamVault Java 应用..."
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Xms256m -Xmx512m \
    -jar /app.jar \
    --spring.profiles.active=docker
