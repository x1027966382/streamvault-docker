FROM alpine:3.20

ENV TZ=Asia/Shanghai

# yt-dlp 版本
ARG BUILD_VERSION=2025.03.31
ENV YT_DLP_VERSION=$BUILD_VERSION

# 安装所有依赖（包括 f2 编译需要的）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk upgrade --update-cache && \
    apk add --no-cache \
        openjdk8 \
        ffmpeg \
        python3 \
        py3-pip \
        py3-virtualenv \
        libffi \
        libssl3 \
        libstdc++ \
        curl \
        wget \
        # f2 编译依赖（pydantic-core, cryptography 等 C 扩展）
        build-base \
        python3-dev \
        libffi-dev \
        openssl-dev \
        cargo \
        rust && \
    rm -rf /tmp/* /var/cache/apk/*

# 创建虚拟环境并安装 f2
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir f2

# 下载 yt-dlp
RUN wget -O /usr/local/bin/yt-dlp \
    https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp
ENV YT_DLP_PATH=/usr/local/bin/yt-dlp

# 清理编译工具（减小镜像体积）
RUN apk del build-base cargo rust python3-dev libffi-dev openssl-dev 2>/dev/null || true

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
