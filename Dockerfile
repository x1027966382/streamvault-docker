# =============================================================================
# StreamVault Docker Package
# Build: docker build --no-cache -t streamvault:latest .
# Run:   docker run -d --name streamvault -p 5999:5999 -v ./data:/app/data --restart unless-stopped streamvault:latest
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

# Download JAR from GitHub releases (built inside Docker, avoids large local transfer)
ARG JAR_URL=https://github.com/x1027966382/StreamVault/releases/latest/download/spirit-0.0.1-SNAPSHOT.jar
RUN wget -O /app.jar "${JAR_URL}" 2>/dev/null || \
    wget -O /app.jar "https://github.com/x1027966382/StreamVault/raw/main/backstage/src/main/docker/buildx/spirit-0.0.1-SNAPSHOT.jar" 2>/dev/null || \
    { echo "ERROR: Failed to download JAR. Please download manually and place spirit-0.0.1-SNAPSHOT.jar in this directory, then rebuild."; exit 1; }

# Expose port
EXPOSE 5999

# Volume mounts for persistence
VOLUME ["/tmp", "/app"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:5999/actuator/health || exit 1

# Start the application
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-Xmx1g", "-jar", "/app.jar", "--spring.profiles.active=docker"]
