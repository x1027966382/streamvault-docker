FROM alpine:3.20

ENV TZ=Asia/Shanghai

# yt-dlp 版本（与原仓库保持一致）
ARG BUILD_VERSION=2025.03.31
ENV YT_DLP_VERSION=$BUILD_VERSION

# 使用国内镜像源加速 + 安装所有依赖
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk upgrade --update-cache && \
    apk add openjdk8 && \
    apk add ffmpeg && \
    apk add python3 py3-pip py3-virtualenv build-base python3-dev libffi-dev && \
    rm -rf /tmp/* /var/cache/apk/*

# 创建 Python 虚拟环境并安装 f2（抖音脚本依赖）
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
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

# 创建资源目录（视频/封面下载存储）
RUN mkdir -p /app/resources

# 复制 JAR（由 workflow 在构建前下载）
ADD spirit-0.0.1-SNAPSHOT.jar app.jar

# 复制启动脚本（自动初始化数据库 + 目录结构）
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 28081

ENTRYPOINT ["/entrypoint.sh"]
