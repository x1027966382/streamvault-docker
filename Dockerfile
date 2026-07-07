FROM openjdk:8-jdk-alpine3.9

# 安装 Python3 + ffmpeg（douyin.py 需要）
RUN apk add --no-cache python3 py3-pip ffmpeg \
    && ln -sf python3 /usr/bin/python

# 应用目录
WORKDIR /app

# 数据卷
VOLUME ["/tmp", "/app"]

# 复制 JAR（由 workflow 在构建前下载）
COPY spirit-0.0.1-SNAPSHOT.jar app.jar

# 复制前端静态资源 + 数据库 + 脚本
COPY static/ /home/app/static/
COPY db/ /home/app/db/
COPY script/ /home/app/script/

# 创建上传目录
RUN mkdir -p /app/upload

# 暴露端口
EXPOSE 28081

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar", "--spring.profiles.active=docker"]
