#!/bin/bash
# 科研通文献下载后自动处理脚本
# 用法: bash process_ablesci_download.sh [PDF文件路径]
# 如果不传参数，则自动处理 Downloads 目录中的所有科研通PDF

PAPERS_DIR="/data/disk/papers"
DOWNLOADS_DIR="/root/Downloads"
DB_PATH="/data/disk/papers/index.db"
LOG="/data/disk/papers/auto_index.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG"
}

# 处理单个PDF文件
process_single_pdf() {
    local PDF_FILE="$1"
    local BASENAME=$(basename "$PDF_FILE")
    
    log_info "处理文件: $BASENAME"
    
    # 检查文件是否存在
    if [ ! -f "$PDF_FILE" ]; then
        log_error "文件不存在: $PDF_FILE"
        return 1
    fi
    
    # 计算文件hash
    local FILE_HASH=$(md5sum "$PDF_FILE" | awk '{print $1}')
    log_info "文件MD5: $FILE_HASH"
    
    # 检查是否已存在
    local EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM papers WHERE file_hash='$FILE_HASH';" 2>/dev/null || echo "0")
    
    if [ "$EXISTS" != "0" ]; then
        log_warn "文件已存在，删除重复下载: $BASENAME"
        rm "$PDF_FILE"
        return 0
    fi
    
    # 移动文件到papers目录
    local DEST_FILE="$PAPERS_DIR/$BASENAME"
    mv "$PDF_FILE" "$DEST_FILE"
    log_info "已移动到: $DEST_FILE"
    
    # 立即索引该文件
    log_info "开始索引..."
    cd "$PAPERS_DIR"
    
    # 使用paper_manager.py索引（只索引新文件）
    python3 "$PAPERS_DIR/paper_manager.py" index 2>&1 | tee -a "$LOG"
    
    # 重命名
    log_info "执行智能重命名..."
    python3 "$PAPERS_DIR/paper_manager.py" rename 2>&1 | tee -a "$LOG"
    
    # 提取全文
    log_info "提取PDF全文..."
    python3 "$PAPERS_DIR/extract_fulltext.py" 2>&1 | tee -a "$LOG"
    
    # AI提炼并发送通知
    log_info "AI智能提炼并发送飞书通知..."
    python3 "$PAPERS_DIR/ai_summarize.py" 2>&1 | tee -a "$LOG"
    
    log_info "✅ 文件处理完成: $BASENAME"
    return 0
}

# 主逻辑
main() {
    log_info "========== 科研通文献下载后处理 =========="
    
    # 如果传了参数，处理指定文件
    if [ $# -gt 0 ]; then
        for PDF_FILE in "$@"; do
            if [[ "$PDF_FILE" == *.pdf ]]; then
                process_single_pdf "$PDF_FILE"
            else
                log_warn "跳过非PDF文件: $PDF_FILE"
            fi
        done
        return 0
    fi
    
    # 否则，自动处理 Downloads 目录
    log_info "扫描 Downloads 目录: $DOWNLOADS_DIR"
    
    local FOUND_COUNT=0
    for PDF_FILE in "$DOWNLOADS_DIR"/*.pdf; do
        if [ -f "$PDF_FILE" ]; then
            # 检查文件名是否包含科研通标识
            if [[ "$(basename "$PDF_FILE")" == *"科研通"* ]] || [[ "$(basename "$PDF_FILE")" == *"ablesci"* ]]; then
                process_single_pdf "$PDF_FILE"
                ((FOUND_COUNT++))
            fi
        fi
    done
    
    if [ "$FOUND_COUNT" -eq 0 ]; then
        log_warn "Downloads 目录中没有找到科研通PDF文件"
    else
        log_info "共处理 $FOUND_COUNT 个文件"
    fi
    
    log_info "========== 处理完成 =========="
}

# 执行主函数
main "$@"
