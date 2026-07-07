#!/bin/bash
set -e

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
detect_proxy() {
    # 检测常见代理端口
    for port in 7890 1080 8080 3128; do
        if curl -s --connect-timeout 2 "http://127.0.0.1:${port}" >/dev/null 2>&1; then
            echo "http://127.0.0.1:${port}"
            return 0
        fi
    done
    # 检测环境变量
    if [ -n "$HTTP_PROXY" ]; then
        echo "$HTTP_PROXY"
        return 0
    fi
    if [ -n "$HTTPS_PROXY" ]; then
        echo "$HTTPS_PROXY"
        return 0
    fi
    return 1
}

PROXY=$(detect_proxy)
if [ -n "$PROXY" ]; then
    log "✅ 检测到代理: $PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    export ALL_PROXY="$PROXY"
    # 写入配置供其他脚本使用
    echo "PROXY=$PROXY" > /app/config/proxy.env
else
    warn "⚠️ 未检测到代理，部分功能可能受限"
    echo "PROXY=" > /app/config/proxy.env
fi

# ===== 4. 验证 Python 环境 =====
log "验证 Python 环境..."
if /opt/venv/bin/python3 --version >/dev/null 2>&1; then
    PY_VERSION=$(/opt/venv/bin/python3 --version 2>&1)
    log "✅ Python: $PY_VERSION"
else
    err "❌ Python 环境异常"
fi

if /opt/venv/bin/python3 -c "import f2" >/dev/null 2>&1; then
    F2_VERSION=$(/opt/venv/bin/python3 -c "import f2; print(f2.__version__)" 2>/dev/null || echo "unknown")
    log "✅ f2 版本: $F2_VERSION"
else
    warn "⚠️ f2 导入失败，尝试重新安装..."
    /opt/venv/bin/pip install --no-cache-dir f2 2>&1 || true
fi

if /opt/venv/bin/python3 -c "from f2.apps.douyin.handler import DouyinHandler" >/dev/null 2>&1; then
    log "✅ DouyinHandler 就绪"
else
    warn "⚠️ DouyinHandler 导入失败"
fi

# ===== 5. 检查 Cookie 文件 =====
if [ -f /app/cookies/douyin.txt ]; then
    COOKIE_SIZE=$(wc -c < /app/cookies/douyin.txt)
    log "✅ 抖音 Cookie 文件存在 (${COOKIE_SIZE} bytes)"
else
    warn "⚠️ 抖音 Cookie 文件不存在，请在后台配置"
fi

# ===== 6. 确保脚本可执行 =====
log "设置脚本权限..."
chmod +x /home/app/script/*.py 2>/dev/null || true
chmod +x /app/scripts/*.sh 2>/dev/null || true

# ===== 7. 启动日志轮转 =====
log "配置日志轮转..."
cat > /etc/logrotate.d/streamvault << 'EOF'
/app/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0644 root root
}
EOF

# ===== 8. 启动定时清理 =====
log "配置定时清理..."
if ! crontab -l 2>/dev/null | grep -q "cleanup.sh"; then
    (echo "0 3 * * * /app/scripts/cleanup.sh >> /app/log/cleanup.log 2>&1") | crontab -
    log "✅ 定时清理已配置 (每天凌晨3点)"
fi

# ===== 9. 启动 StreamVault =====
log "启动 StreamVault Java 应用..."
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Xms256m -Xmx512m \
    -jar /app.jar \
    --spring.profiles.active=docker
