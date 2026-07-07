# ============================================
# Stage 1: 在 Debian 上编译 Python 依赖（兼容性好）
# ============================================
FROM python:3.11-slim AS builder

WORKDIR /build

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    python3-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 创建虚拟环境并安装 f2
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir f2

# ============================================
# Stage 2: Alpine 运行时镜像（含 Java + Python）
# ============================================
FROM alpine:3.20

ENV TZ=Asia/Shanghai

# yt-dlp 版本
ARG BUILD_VERSION=2025.03.31
ENV YT_DLP_VERSION=$BUILD_VERSION

# 安装系统依赖
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk upgrade --update-cache && \
    apk add --no-cache \
        openjdk8 \
        ffmpeg \
        python3 \
        libffi \
        libssl3 \
        libstdc++ \
        curl \
        wget && \
    rm -rf /tmp/* /var/cache/apk/*

# 从 builder 阶段复制编译好的 Python 虚拟环境
COPY --from=builder /opt/venv /opt/venv

# 下载 yt-dlp
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

# 复制 JAR
ADD spirit-0.0.1-SNAPSHOT.jar app.jar

# 启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 28081

ENTRYPOINT ["/entrypoint.sh"]
