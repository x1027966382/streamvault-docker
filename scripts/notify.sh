#!/bin/bash
# ===== 下载完成通知脚本 =====
# 支持 Telegram / Server酱 / PushPlus 推送
# 用法: bash notify.sh "标题" "内容"
#       bash notify.sh "标题" "内容" "/path/to/file.jpg"

set -e

TITLE="${1:-StreamVault 通知}"
CONTENT="${2:-下载任务已完成}"
IMAGE_PATH="${3:-}"

LOG_FILE="/app/log/notify.log"
ENV_FILE="/app/config/proxy.env"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 加载代理配置
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# 加载通知配置（从 .env 文件）
load_config() {
    local env_file="${1:-/app/config/.env}"
    if [ -f "$env_file" ]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            export "$key=$value"
        done < "$env_file"
    fi
}

load_config "/app/config/.env"

# ===== Telegram 推送 =====
send_telegram() {
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        return 1
    fi
    
    local api_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    local message="🎬 *${TITLE}*\n\n${CONTENT}"
    
    if [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
        # 发送图片
        curl -s -F "chat_id=${TELEGRAM_CHAT_ID}" \
             -F "photo=@${IMAGE_PATH}" \
             -F "caption=${message}" \
             -F "parse_mode=Markdown" \
             "$api_url" >/dev/null 2>&1
    else
        # 发送文本
        curl -s -d "chat_id=${TELEGRAM_CHAT_ID}" \
             -d "text=${message}" \
             -d "parse_mode=Markdown" \
             "$api_url" >/dev/null 2>&1
    fi
    
    log "✅ Telegram 通知已发送"
    return 0
}

# ===== Server酱 推送 =====
send_serverchan() {
    if [ -z "$SERVERCHAN_KEY" ]; then
        return 1
    fi
    
    local api_url="https://sctapi.ftqq.com/${SERVERCHAN_KEY}.send"
    
    curl -s -d "title=${TITLE}&desp=${CONTENT}" \
         "$api_url" >/dev/null 2>&1
    
    log "✅ Server酱通知已发送"
    return 0
}

# ===== PushPlus 推送 =====
send_pushplus() {
    if [ -z "$PUSHPLUS_TOKEN" ]; then
        return 1
    fi
    
    local api_url="http://www.pushplus.plus/send"
    
    curl -s -X POST "$api_url" \
         -H "Content-Type: application/json" \
         -d "{
            \"token\": \"${PUSHPLUS_TOKEN}\",
            \"title\": \"${TITLE}\",
            \"content\": \"${CONTENT}\",
            \"template\": \"markdown\"
         }" >/dev/null 2>&1
    
    log "✅ PushPlus 通知已发送"
    return 0
}

# ===== 钉钉 推送 =====
send_dingtalk() {
    if [ -z "$DINGTALK_WEBHOOK" ]; then
        return 1
    fi
    
    curl -s -X POST "$DINGTALK_WEBHOOK" \
         -H "Content-Type: application/json" \
         -d "{
            \"msgtype\": \"markdown\",
            \"markdown\": {
                \"title\": \"${TITLE}\",
                \"text\": \"## ${TITLE}\n\n${CONTENT}\"
            }
         }" >/dev/null 2>&1
    
    log "✅ 钉钉通知已发送"
    return 0
}

# ===== 主流程 =====
main() {
    log "发送通知: $TITLE"
    
    local sent=false
    
    # 按优先级发送通知
    if send_telegram; then sent=true; fi
    if send_serverchan; then sent=true; fi
    if send_pushplus; then sent=true; fi
    if send_dingtalk; then sent=true; fi
    
    if [ "$sent" = false ]; then
        log "⚠️ 未配置任何通知渠道"
    fi
}

# 运行
main
