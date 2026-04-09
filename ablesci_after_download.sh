#!/bin/bash
# 科研通文献下载后处理 - 浏览器自动化调用脚本
# 此脚本应在浏览器下载完成后调用

PAPERS_DIR="/data/disk/papers"
DOWNLOADS_DIR="/root/Downloads"
DB_PATH="/data/disk/papers/index.db"
LOG="/data/disk/papers/auto_index.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 科研通文献下载后处理开始" >> "$LOG"

# 等待文件下载完成（最多等待10秒）
sleep 2

# 查找最新的科研通PDF文件
LATEST_PDF=$(ls -t "$DOWNLOADS_DIR"/*科研通*.pdf "$DOWNLOADS_DIR"/*ablesci*.pdf 2>/dev/null | head -1)

if [ -z "$LATEST_PDF" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未找到科研通PDF文件" >> "$LOG"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 找到下载文件: $(basename "$LATEST_PDF")" >> "$LOG"

# 检查文件是否已存在（通过hash比对）
FILE_HASH=$(md5sum "$LATEST_PDF" | awk '{print $1}')
EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM papers WHERE file_hash='$FILE_HASH';" 2>/dev/null || echo "0")

if [ "$EXISTS" != "0" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件已存在，删除重复下载: $(basename "$LATEST_PDF")" >> "$LOG"
    rm "$LATEST_PDF"
    exit 0
fi

# 移动文件到papers目录
mv "$LATEST_PDF" "$PAPERS_DIR/"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 已移动到papers目录" >> "$LOG"

# 触发完整处理流程
cd "$PAPERS_DIR"
python3 "$PAPERS_DIR/paper_manager.py" index >> "$LOG" 2>&1
python3 "$PAPERS_DIR/paper_manager.py" rename >> "$LOG" 2>&1
python3 "$PAPERS_DIR/extract_fulltext.py" >> "$LOG" 2>&1
python3 "$PAPERS_DIR/ai_summarize.py" >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 科研通文献处理完成" >> "$LOG"
