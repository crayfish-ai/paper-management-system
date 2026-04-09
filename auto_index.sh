#!/bin/bash
#=============================================================================
# Paper Management System - Auto Index Script
# 
# 功能：增量索引 + 自动移动下载文件 + 全文提取 + AI提炼
# 配置：所有配置通过 config.yaml 或环境变量 PAPERMGR_* 设置
#=============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load configuration
CONFIG_FILE="${PROJECT_DIR}/config.yaml"

# Default values (will be overridden by config.py)
PAPERS_DIR="${PAPERMGR_PAPERS_DIR:-/data/disk/papers}"
DOWNLOADS_DIR="${PAPERMGR_DOWNLOADS_DIR:-/root/Downloads}"
DB_PATH="${PAPERMGR_DATABASE_PATH:-/data/disk/papers/index.db}"
LOG="${PAPERMGR_LOGGING_PATH:-/data/disk/papers/auto_index.log}"

# Helper: run Python with config
python_cfg() {
    python3 -c "
import sys
sys.path.insert(0, '$PROJECT_DIR')
from config import get_config
cfg = get_config()
print(cfg.$1)
" 2>/dev/null || echo "${2:-}"
}

# Override from config if available
if [ -f "${PROJECT_DIR}/config.py" ]; then
    PAPERS_DIR=$(python_cfg papers_dir "$PAPERS_DIR")
    DOWNLOADS_DIR=$(python_cfg downloads_dir "$DOWNLOADS_DIR")
fi

cd "$PAPERS_DIR"

#=============================================================================
# Step 1: 从 Downloads 目录移动新PDF文件
#=============================================================================
MOVED_COUNT=0
for f in "$DOWNLOADS_DIR"/*.pdf; do
    if [ -f "$f" ]; then
        if [[ "$(basename "$f")" == *"科研通"* ]] || [[ "$(basename "$f")" == *"ablesci"* ]]; then
            FILE_HASH=$(md5sum "$f" | awk '{print $1}')
            EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM papers WHERE file_hash='$FILE_HASH';" 2>/dev/null || echo "0")
            
            if [ "$EXISTS" = "0" ]; then
                mv "$f" "$PAPERS_DIR/"
                echo "[$(date)] 移动文件: $(basename "$f")" >> "$LOG"
                ((MOVED_COUNT++))
            else
                echo "[$(date)] 跳过已存在文件: $(basename "$f")" >> "$LOG"
                rm -f "$f"
            fi
        fi
    fi
done

if [ "$MOVED_COUNT" -gt 0 ]; then
    echo "[$(date)] 从Downloads移动了 $MOVED_COUNT 个新文件" >> "$LOG"
fi

#=============================================================================
# Step 2: 检测并索引新文件
#=============================================================================
NEW_COUNT=$(python3 -c "
import sys
sys.path.insert(0, '$PROJECT_DIR')
from config import get_config
from paper_manager import get_db
import hashlib, glob

cfg = get_config()
conn = get_db()
indexed = set(r[0] for r in conn.execute('SELECT file_hash FROM papers').fetchall())
new = 0
for f in glob.glob(cfg.papers_dir + '/*.pdf'):
    try:
        h = hashlib.md5(open(f,'rb').read()).hexdigest()
        if h not in indexed:
            new += 1
    except:
        pass
conn.close()
print(new)
" 2>/dev/null || echo "0")

if [ "$NEW_COUNT" -gt 0 ]; then
    echo "[$(date)] 发现 $NEW_COUNT 个新文件，开始索引..." >> "$LOG"
    
    # 索引
    python3 "${PROJECT_DIR}/paper_manager.py" index >> "$LOG" 2>&1
    
    # 重命名
    python3 "${PROJECT_DIR}/paper_manager.py" rename >> "$LOG" 2>&1

    # 全文提取（仅新文件）
    echo "[$(date)] 检查全文提取..." >> "$LOG"
    python3 "${PROJECT_DIR}/extract_fulltext.py" >> "$LOG" 2>&1

    # AI提炼
    if [ -f "${PROJECT_DIR}/config.py" ]; then
        AI_ENABLED=$(python3 -c "
import sys
sys.path.insert(0, '$PROJECT_DIR')
from config import get_config
cfg = get_config()
print('true' if cfg.ai_enabled else 'false')
" 2>/dev/null)
        if [ "$AI_ENABLED" = "true" ]; then
            echo "[$(date)] 开始AI提炼..." >> "$LOG"
            python3 "${PROJECT_DIR}/ai_summarize.py" >> "$LOG" 2>&1
        fi
    fi

    echo "[$(date)] 索引+全文+AI提炼完成" >> "$LOG"
else
    echo "[$(date)] 没有新文件" >> "$LOG"
fi
