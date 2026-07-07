#!/bin/bash
# ===== 定时清理脚本 =====
# 自动清理过期临时文件、重复下载、过期日志
# 用法: bash cleanup.sh

set -e

LOG_FILE="/app/log/cleanup.log"
DOWNLOAD_DIR="/app/downloads"
TEMP_DIR="/tmp"
LOG_DIR="/app/log"
MAX_LOG_DAYS=30
MAX_TEMP_DAYS=1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== 开始清理 ====="

# ===== 1. 清理临时文件 =====
log "清理临时文件..."
find "$TEMP_DIR" -type f \( -name "*.tmp" -o -name "*.part" -o -name "*.downloading" \) -mtime +$MAX_TEMP_DAYS -delete 2>/dev/null || true
log "✅ 临时文件清理完成"

# ===== 2. 清理过期日志 =====
log "清理过期日志..."
find "$LOG_DIR" -type f -name "*.log" -size +10M -exec truncate -s 1M {} \; 2>/dev/null || true
find "$LOG_DIR" -type f -name "*.log.*" -mtime +$MAX_LOG_DAYS -delete 2>/dev/null || true
log "✅ 日志清理完成"

# ===== 3. 清理重复文件（基于文件名） =====
log "检查重复文件..."
dup_count=0
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    # 查找同名文件
    duplicates=$(find "$DOWNLOAD_DIR" -name "$filename" -not -path "$file" 2>/dev/null | head -1)
    if [ -n "$duplicates" ]; then
        # 保留较大的文件
        size1=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        size2=$(stat -f%z "$duplicates" 2>/dev/null || stat -c%s "$duplicates" 2>/dev/null || echo 0)
        if [ "$size1" -lt "$size2" ]; then
            rm -f "$file"
            ((dup_count++))
            log "  删除重复: $filename (保留较大的副本)"
        fi
    fi
done < <(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -print0)
log "✅ 清理 $dup_count 个重复文件"

# ===== 4. 清理 Aria2 会话文件 =====
log "清理 Aria2 会话..."
if [ -f /app/aria2/aria2.session ]; then
    # 清理已完成的会话条目
    sed -i '/^$/d' /app/aria2/aria2.session 2>/dev/null || true
fi
log "✅ Aria2 会话清理完成"

# ===== 5. 清理空目录 =====
log "清理空目录..."
find "$DOWNLOAD_DIR" -type d -empty -delete 2>/dev/null || true
log "✅ 空目录清理完成"

# ===== 6. 统计磁盘使用 =====
log "统计磁盘使用..."
usage=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1 || echo "unknown")
log "当前下载目录大小: $usage"

log "===== 清理完成 ====="
