#!/bin/sh
set -e

# ===== StreamVault 初始化脚本 =====

# 1. 数据库初始化：如果 /app/db/spirit.db 不存在，从镜像内置拷贝
if [ ! -f /app/db/spirit.db ]; then
    echo "[init] 首次启动，初始化数据库..."
    mkdir -p /app/db
    cp /home/app/db/* /app/db/
    echo "[init] 数据库已初始化: /app/db/spirit.db"
fi

# 2. 创建必要目录
mkdir -p /app/resources
mkdir -p /app/log
mkdir -p /app/cookies
mkdir -p /tmp

# 3. 确保脚本可执行
chmod +x /home/app/script/*.py 2>/dev/null || true

# 4. 验证 Python 环境（调试用）
echo "[init] 验证 Python 环境..."
/opt/venv/bin/python3 --version 2>&1 || echo "[init] ⚠️ Python 环境异常"
/opt/venv/bin/python3 -c "import f2; print('[init] f2 版本:', f2.__version__)" 2>&1 || echo "[init] ⚠️ f2 包导入失败"
/opt/venv/bin/python3 -c "from f2.apps.douyin.handler import DouyinHandler; print('[init] DouyinHandler 导入成功')" 2>&1 || echo "[init] ⚠️ DouyinHandler 导入失败"

echo "[init] 目录结构就绪，启动 StreamVault..."

# 启动 Java 应用
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -jar /app.jar \
    --spring.profiles.active=docker
