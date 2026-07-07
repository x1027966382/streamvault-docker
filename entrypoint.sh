#!/bin/sh
set -e

# ===== StreamVault 初始化脚本 =====

echo "[init] StreamVault 启动中..."

# 1. 数据库初始化
if [ ! -f /app/db/spirit.db ]; then
    echo "[init] 首次启动，初始化数据库..."
    mkdir -p /app/db
    cp /home/app/db/* /app/db/
    echo "[init] ✅ 数据库已初始化"
else
    echo "[init] 数据库已存在，跳过初始化"
fi

# 2. 创建必要目录
mkdir -p /app/resources /app/log /app/cookies /tmp

# 3. 确保脚本可执行
chmod +x /home/app/script/*.py 2>/dev/null || true

# 4. 验证 Python 环境
echo "[init] 验证 Python 环境..."
PY_VERSION=$(/opt/venv/bin/python3 --version 2>&1)
echo "[init] Python: $PY_VERSION"

/opt/venv/bin/python3 -c "import f2; print('[init] f2 版本:', f2.__version__)" 2>&1 || {
    echo "[init] ⚠️ f2 导入失败，尝试重新安装..."
    /opt/venv/bin/pip install --no-cache-dir f2 2>&1 || true
}

/opt/venv/bin/python3 -c "from f2.apps.douyin.handler import DouyinHandler; print('[init] ✅ DouyinHandler 就绪')" 2>&1 || {
    echo "[init] ⚠️ DouyinHandler 导入失败"
    echo "[init] 请检查 /app/cookies/douyin.txt 是否存在有效的 Cookie"
}

# 5. 检查 Cookie 文件
if [ -f /app/cookies/douyin.txt ]; then
    COOKIE_SIZE=$(wc -c < /app/cookies/douyin.txt)
    echo "[init] ✅ 抖音 Cookie 文件存在 (${COOKIE_SIZE} bytes)"
else
    echo "[init] ⚠️ 抖音 Cookie 文件不存在，请在后台配置"
fi

echo "[init] 启动 StreamVault..."

# 启动 Java 应用
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -jar /app.jar \
    --spring.profiles.active=docker
