#!/usr/bin/env python3
"""
Paper Management System - Main Entry Point

Unified CLI for all paper management operations.
Replaces shell scripts for core operations.

Usage:
    python3 paper_management.py index          # Index all PDFs
    python3 paper_management.py rename         # Rename all indexed PDFs
    python3 paper_management.py auto          # Full auto-index workflow
    python3 paper_management.py extract       # Extract full text
    python3 paper_management.py summarize      # AI summarization
    python3 paper_management.py status         # Show index status
    python3 paper_management.py search <term>  # Search papers
"""

import sys
import os
import glob
import hashlib
from pathlib import Path

# Add project directory to path
PROJECT_DIR = Path(__file__).parent
sys.path.insert(0, str(PROJECT_DIR))

from config import get_config
from paper_manager import get_db, init_db, extract_meta

def cmd_index():
    """Index all PDFs in papers directory"""
    cfg = get_config()
    papers_dir = cfg.papers_dir
    
    init_db()
    conn = get_db()
    
    # Get already indexed hashes
    indexed = set(row[0] for row in conn.execute("SELECT file_hash FROM papers").fetchall())
    
    pdf_files = glob.glob(os.path.join(papers_dir, "*.pdf"))
    new_count = 0
    skip_count = 0
    
    for fpath in pdf_files:
        try:
            with open(fpath, "rb") as f:
                fhash = hashlib.md5(f.read()).hexdigest()
            
            if fhash in indexed:
                skip_count += 1
                continue
            
            meta = extract_meta(fpath)
            fsize = os.path.getsize(fpath)
            
            conn.execute("""
                INSERT OR IGNORE INTO papers 
                (file_hash, filename, filepath, title, authors, doi, year, journal, abstract, pages, file_size)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                fhash, os.path.basename(fpath), fpath,
                meta.get("title"), meta.get("authors"), meta.get("doi"),
                meta.get("year"), meta.get("journal"), meta.get("abstract"),
                meta.get("pages", 0), fsize
            ))
            new_count += 1
            indexed.add(fhash)
        except Exception as e:
            print(f"  ERROR: {os.path.basename(fpath)}: {e}", file=sys.stderr)
    
    conn.commit()
    conn.close()
    
    print(f"索引完成: 新增 {new_count}, 跳过(已存在) {skip_count}")

def cmd_rename():
    """Rename all indexed PDFs"""
    import re
    from paper_manager import rename_all
    rename_all()

def cmd_extract():
    """Extract full text from PDFs"""
    from extract_fulltext import extract_all
    extract_all()

def cmd_summarize():
    """AI summarization"""
    from ai_summarize import main as summarize_main
    summarize_main()

def cmd_status():
    """Show status"""
    from paper_manager import status
    status()

def cmd_search(term):
    """Search papers"""
    from paper_manager import search
    search(term)

def cmd_auto():
    """
    Full auto-index workflow:
    1. Move new PDFs from downloads
    2. Index new PDFs
    3. Rename indexed PDFs
    4. Extract full text
    5. AI summarization (if enabled)
    """
    import subprocess
    import time
    
    cfg = get_config()
    papers_dir = cfg.papers_dir
    downloads_dir = cfg.downloads_dir
    
    print("=== Paper Management System Auto-Index ===")
    
    # Step 1: Move new PDFs from downloads
    moved = 0
    for keyword in cfg.get("downloads.keywords", ["科研通", "ablesci"]):
        for f in glob.glob(os.path.join(downloads_dir, "*.pdf")):
            if keyword in os.path.basename(f):
                try:
                    # Check if already exists
                    fhash = hashlib.md5(open(f, "rb").read()).hexdigest()
                    conn = get_db()
                    exists = conn.execute(
                        "SELECT COUNT(*) FROM papers WHERE file_hash=?", (fhash,)
                    ).fetchone()[0] > 0
                    conn.close()
                    
                    if not exists:
                        os.rename(f, os.path.join(papers_dir, os.path.basename(f)))
                        moved += 1
                        print(f"  移动: {os.path.basename(f)}")
                except Exception as e:
                    print(f"  移动失败: {os.path.basename(f)}: {e}")
    
    if moved > 0:
        print(f"已移动 {moved} 个新文件")
    else:
        print("没有新文件需要移动")
    
    # Step 2: Index new PDFs
    print("\n开始索引...")
    cmd_index()
    
    # Step 3: Rename
    print("\n开始重命名...")
    cmd_rename()
    
    # Step 4: Extract full text
    print("\n检查全文提取...")
    conn = get_db()
    need_extract = conn.execute(
        "SELECT COUNT(*) FROM papers WHERE full_text IS NULL OR full_text = ''"
    ).fetchone()[0]
    conn.close()
    
    if need_extract > 0:
        print(f"需要提取 {need_extract} 篇")
        cmd_extract()
    else:
        print("全文提取完成")
    
    # Step 5: AI summarization (if enabled)
    if cfg.ai_enabled:
        print("\n开始AI提炼...")
        cmd_summarize()
    else:
        print("\nAI提炼未启用 (ai.enabled=false)")
    
    print("\n=== 完成 ===")

USAGE = """Paper Management System

用法:
    python3 paper_management.py index          # 索引所有PDF
    python3 paper_management.py rename         # 重命名PDF
    python3 paper_management.py auto           # 全自动流程
    python3 paper_management.py extract        # 提取全文
    python3 paper_management.py summarize      # AI提炼
    python3 paper_management.py status         # 状态
    python3 paper_management.py search <term>   # 搜索

配置: config.yaml 或环境变量 PAPERMGR_*
"""

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(USAGE)
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "index":
        cmd_index()
    elif cmd == "rename":
        cmd_rename()
    elif cmd == "auto":
        cmd_auto()
    elif cmd == "extract":
        cmd_extract()
    elif cmd == "summarize":
        cmd_summarize()
    elif cmd == "status":
        cmd_status()
    elif cmd == "search":
        cmd_search(" ".join(sys.argv[2:]))
    else:
        print(f"未知命令: {cmd}")
        print(USAGE)
        sys.exit(1)
