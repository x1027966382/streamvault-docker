FROM openjdk:8-jdk-alpine3.9

# 安装 Python3 + ffmpeg + curl（douyin.py 需要）
RUN apk add --no-cache python3 py3-pip ffmpeg curl \
    && ln -sf python3 /usr/bin/python

# 应用目录
WORKDIR /app

# 数据卷
VOLUME ["/tmp", "/app"]

# 从 GitHub 下载 JAR（60MB，不随仓库分发）
ARG JAR_URL=https://raw.githubusercontent.com/x1027966382/StreamVault/main/backstage/src/main/docker/buildx/spirit-0.0.1-SNAPSHOT.jar
RUN curl -L -o /app/app.jar "${JAR_URL}"

# 复制前端静态资源 + 数据库 + 脚本
COPY static/ /home/app/static/
COPY db/ /home/app/db/
COPY script/ /home/app/script/

# 创建上传目录
RUN mkdir -p /app/upload

# 暴露端口
EXPOSE 28081

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar", "--spring.profiles.active=docker"]
