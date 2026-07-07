FROM eclipse-temurin:8-jre-jammy

ENV TZ=Asia/Shanghai

# yt-dlp 版本（与原仓库保持一致）
ARG BUILD_VERSION=2025.03.31
ENV YT_DLP_VERSION=$BUILD_VERSION

# 使用阿里云镜像源加速 + 安装所有依赖
RUN sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true && \
    apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    ffmpeg \
    curl wget \
    libcurl4-openssl-dev libssl-dev build-essential libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# 创建 Python 虚拟环境并安装 f2（抖音脚本依赖）
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir f2

# 下载 yt-dlp（视频下载工具）
RUN wget -O /usr/local/bin/yt-dlp \
    https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp
ENV YT_DLP_PATH=/usr/local/bin/yt-dlp

# 数据卷
VOLUME ["/tmp", "/app"]

# 复制数据库 + 脚本
COPY db /home/app/db/
COPY script /home/app/script/

# 创建必要目录
RUN mkdir -p /app/resources /app/log /app/cookies

# 复制 JAR（由 workflow 在构建前下载）
ADD spirit-0.0.1-SNAPSHOT.jar app.jar

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 28081

ENTRYPOINT ["/entrypoint.sh"]
