#!/bin/bash
# ===== Emby/Jellyfin NFO 元数据生成脚本 =====
# 自动为下载的视频生成 NFO 文件 + 封面
# 用法: bash nfo-gen.sh [视频目录]

set -e

VIDEO_DIR="${1:-/app/downloads}"
LOG_FILE="/app/log/nfo-gen.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# XML 转义
xml_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# 生成 NFO 文件
generate_nfo() {
    local video_file="$1"
    local filename=$(basename "$video_file")
    local name="${filename%.*}"
    local dir=$(dirname "$video_file")
    local nfo_file="$dir/$name.nfo"
    
    # 跳过已存在的 NFO
    if [ -f "$nfo_file" ]; then
        return
    fi
    
    # 提取信息
    local title=$(xml_escape "$name")
    local plot=""
    local thumb=""
    local date=$(date '+%Y-%m-%d')
    
    # 尝试从文件名提取更多信息
    if [[ "$name" =~ @([^-@]+) ]]; then
        local creator="${BASH_REMATCH[1]}"
        local creator_escaped=$(xml_escape "$creator")
    fi
    
    # 生成 NFO
    cat > "$nfo_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<movie>
  <title>${title}</title>
  <originaltitle>${title}</originaltitle>
  <plot>${plot:-下载自视频平台}</plot>
  <thumb>${thumb}</thumb>
  <year>$(date '+%Y')</year>
  <premiered>${date}</premiered>
  <dateadded>${date}</dateadded>
  <uniqueid type="streamvault" default="true">${name}</uniqueid>
</movie>
EOF
    
    log "✅ 生成 NFO: $name.nfo"
    
    # 尝试下载封面
    if [ -n "$thumb" ]; then
        local thumb_file="$dir/$name-poster.jpg"
        if [ ! -f "$thumb_file" ]; then
            curl -s -o "$thumb_file" "$thumb" 2>/dev/null || true
        fi
    fi
}

# 处理目录
process_directory() {
    local dir="$1"
    
    # 查找视频文件
    while IFS= read -r -d '' video; do
        generate_nfo "$video"
    done < <(find "$dir" -maxdepth 1 -type f \( \
        -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \
        -o -name "*.mov" -o -name "*.flv" -o -name "*.webm" \
    \) -print0)
}

# 主流程
main() {
    log "开始生成 NFO 元数据..."
    log "扫描目录: $VIDEO_DIR"
    
    # 递归处理所有目录
    while IFS= read -r -d '' dir; do
        process_directory "$dir"
    done < <(find "$VIDEO_DIR" -mindepth 1 -type d -print0)
    
    # 统计
    local nfo_count=$(find "$VIDEO_DIR" -name "*.nfo" | wc -l)
    log "完成，共生成 $nfo_count 个 NFO 文件"
}

# 运行
main
