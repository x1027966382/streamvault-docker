#!/bin/bash
# ===== 智能目录整理脚本 =====
# 按 平台/创作者/日期 自动整理下载文件
# 用法: bash organize.sh [下载目录]

set -e

DOWNLOAD_DIR="${1:-/app/downloads}"
LOG_FILE="/app/log/organize.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 从文件名提取平台信息
detect_platform() {
    local filename="$1"
    case "$filename" in
        *douyin*|*抖音*|*tiktok*) echo "douyin" ;;
        *bilibili*|*b站*|*B站*) echo "bilibili" ;;
        *youtube*|*yt*|*YouTube*) echo "youtube" ;;
        *kuaishou*|*快手*) echo "kuaishou" ;;
        *) echo "others" ;;
    esac
}

# 从文件名提取创作者信息
extract_creator() {
    local filename="$1"
    # 尝试提取 @用户名 模式
    if [[ "$filename" =~ @([^@\s]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    # 尝试提取 creator_ 模式
    elif [[ "$filename" =~ creator_([^_]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "unknown"
    fi
}

# 从文件名提取日期
extract_date() {
    local filename="$1"
    # 尝试提取 YYYYMMDD 模式
    if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    # 尝试提取 YYYY-MM-DD 模式
    elif [[ "$filename" =~ ([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    else
        echo "$(date '+%Y-%m-%d')"
    fi
}

# 整理单个文件
organize_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # 跳过临时文件
    if [[ "$filename" == *.tmp || "$filename" == *.part || "$filename" == *.downloading ]]; then
        return
    fi
    
    # 检测平台
    local platform=$(detect_platform "$filename")
    
    # 提取创作者
    local creator=$(extract_creator "$filename")
    
    # 提取日期
    local file_date=$(extract_date "$filename")
    
    # 构建目标目录
    local target_dir="$DOWNLOAD_DIR/$platform/$creator/$file_date"
    mkdir -p "$target_dir"
    
    # 移动文件
    if [ "$file" != "$target_dir/$filename" ]; then
        mv "$file" "$target_dir/" 2>/dev/null && \
            log "✅ $filename → $platform/$creator/$file_date/" || \
            log "⚠️ 移动失败: $filename"
    fi
}

# 主流程
main() {
    log "开始整理下载文件..."
    log "扫描目录: $DOWNLOAD_DIR"
    
    # 统计
    local count=0
    
    # 扫描所有下载文件
    while IFS= read -r -d '' file; do
        organize_file "$file"
        ((count++))
    done < <(find "$DOWNLOAD_DIR" -maxdepth 1 -type f -print0)
    
    log "整理完成，共处理 $count 个文件"
    
    # 显示整理结果
    log "目录结构:"
    find "$DOWNLOAD_DIR" -mindepth 2 -maxdepth 4 -type d | head -20 | while read dir; do
        log "  $(echo $dir | sed "s|$DOWNLOAD_DIR/||")"
    done
}

# 运行
main
