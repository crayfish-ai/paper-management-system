#!/bin/bash
# 科研通文献下载后即时处理脚本（轻量版）
# 由浏览器下载后自动调用
#
# 使用方法:
# 1. 在浏览器自动化脚本中，下载完成后调用:
#    bash /data/disk/papers/after_download.sh
#
# 2. 或指定文件路径:
#    bash /data/disk/papers/after_download.sh /root/Downloads/xxx.pdf

PAPERS_DIR="/data/disk/papers"
DOWNLOADS_DIR="/root/Downloads"
DB_PATH="/data/disk/papers/index.db"
LOG="/data/disk/papers/auto_index.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== 文献下载后处理开始 ==========" >> "$LOG"

# 获取下载的文件路径（从参数或自动查找）
DOWNLOADED_FILE="${1:-}"

# 如果没有参数，等待2秒后查找最新的科研通PDF
if [ -z "$DOWNLOADED_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 等待文件下载完成..." >> "$LOG"
    sleep 2
    
    # 查找 Downloads 目录最新的科研通PDF
    DOWNLOADED_FILE=$(ls -t "$DOWNLOADS_DIR"/*科研通*.pdf "$DOWNLOADS_DIR"/*ablesci*.pdf 2>/dev/null | head -1)
fi

# 检查文件是否存在
if [ -z "$DOWNLOADED_FILE" ] || [ ! -f "$DOWNLOADED_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] 未找到PDF文件" >> "$LOG"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 处理文件: $(basename "$DOWNLOADED_FILE")" >> "$LOG"

# 检查文件大小（确保下载完成）
FILE_SIZE=$(stat -c%s "$DOWNLOADED_FILE" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 1000 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] 文件太小(${FILE_SIZE}字节)，可能下载未完成，等待3秒..." >> "$LOG"
    sleep 3
    FILE_SIZE=$(stat -c%s "$DOWNLOADED_FILE" 2>/dev/null || echo "0")
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件大小: $(numfmt --to=iec $FILE_SIZE)" >> "$LOG"

# 检查是否已存在（去重）
FILE_HASH=$(md5sum "$DOWNLOADED_FILE" | awk '{print $1}')
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件MD5: $FILE_HASH" >> "$LOG"

EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM papers WHERE file_hash='$FILE_HASH';" 2>/dev/null || echo "0")

if [ "$EXISTS" != "0" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] 文件已存在，删除重复下载" >> "$LOG"
    rm "$DOWNLOADED_FILE"
    exit 0
fi

# 移动到papers目录
FILENAME=$(basename "$DOWNLOADED_FILE")
mv "$DOWNLOADED_FILE" "$PAPERS_DIR/"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] 已移动到: $PAPERS_DIR/$FILENAME" >> "$LOG"

# 触发完整处理流程
cd "$PAPERS_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始索引..." >> "$LOG"
python3 "$PAPERS_DIR/paper_manager.py" index >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 执行智能重命名..." >> "$LOG"
python3 "$PAPERS_DIR/paper_manager.py" rename >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 提取PDF全文..." >> "$LOG"
python3 "$PAPERS_DIR/extract_fulltext.py" >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] AI智能提炼并发送飞书通知..." >> "$LOG"
python3 "$PAPERS_DIR/ai_summarize.py" >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== 文献处理完成 ==========" >> "$LOG"
