# =============================================================================
# StreamVault Docker Package
# Build: docker build -t streamvault:latest .
# Run:   docker run -d --name streamvault -p 28081:28081 -v ./data:/app/data --restart unless-stopped streamvault:latest
# =============================================================================

# ----- Stage 1: Builder -----
FROM python:3.10-alpine AS builder

ENV TZ=Asia/Shanghai
ARG YT_DLP_VERSION=2025.03.31

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk add --no-cache build-base libffi-dev python3-dev wget

# Create virtual environment and install f2 (video downloader)
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir f2

# Download yt-dlp
RUN wget -O /usr/local/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# ----- Stage 2: Runtime -----
FROM openjdk:8-jre-alpine

ENV TZ=Asia/Shanghai

# Copy python venv and yt-dlp from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/bin/yt-dlp /usr/local/bin/yt-dlp

ENV PATH="/opt/venv/bin:$PATH"
ENV YT_DLP_PATH=/usr/local/bin/yt-dlp

# Install ffmpeg for media processing
RUN apk add --no-cache ffmpeg

# Create app directories
RUN mkdir -p /app/resources /app/db /app/script /tmp

# Copy db and script
COPY db /app/db/
COPY script /app/script/

# Copy local JAR file (user must place spirit-0.0.1-SNAPSHOT.jar in this directory before building)
COPY spirit-0.0.1-SNAPSHOT.jar /app.jar

# Expose port (matches original StreamVault default)
EXPOSE 28081

# Volume mounts for persistence
VOLUME ["/tmp", "/app"]

# Start the application
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-Xmx1g", "-jar", "/app.jar", "--spring.profiles.active=docker"]
