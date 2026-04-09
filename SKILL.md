---
name: paper-management-system
description: 文献管理系统 - 自动化PDF文献索引、搜索、AI提炼工具。当用户需要管理PDF文献、自动索引、搜索文献、提取元数据时激活。
metadata:
  {
    "openclaw":
      {
        "emoji": "📚",
        "tags": ["pdf", "papers", "research", "academic", "indexing"],
      },
  }
---

# Paper Management System

文献管理系统 - 自动化PDF文献管理工具（v2.0）

## 功能特性

- 📄 **自动索引**: 扫描PDF文件，提取元数据（标题、作者、DOI等）
- 🔍 **智能搜索**: 支持标题、作者、DOI、摘要等多字段搜索
- 🏷️ **自动重命名**: 按规范格式重命名PDF文件
- 📚 **全文提取**: 提取PDF文本内容便于检索
- 🤖 **AI提炼**: 自动提取研究背景、方法、结果、结论（可选）
- 🔔 **飞书通知**: 新文献入库自动通知（可选，需feishu-relay）
- 🔄 **定时任务**: 支持cron定时自动扫描
- ⚙️ **配置外置**: 通过 config.yaml 或环境变量配置

## 安装

```bash
pip install -r requirements.txt
cp config.example.yaml config.yaml
```

## 配置

### config.yaml（推荐）

```yaml
database:
  path: "/data/disk/papers/index.db"

papers:
  dir: "/data/disk/papers"

ai:
  enabled: false

notification:
  enabled: false
  cmd: "/usr/local/bin/notify"  # 或 "stdout"
```

### 环境变量

```bash
export PAPERMGR_DATABASE_PATH="/data/disk/papers/index.db"
export PAPERMGR_PAPERS_DIR="/data/disk/papers"
export PAPERMGR_AI_ENABLED="false"
export PAPERMGR_NOTIFICATION_ENABLED="false"
```

## 使用

```bash
python3 paper_manager.py index    # 索引
python3 paper_manager.py rename   # 重命名
python3 paper_manager.py search <关键词>  # 搜索
python3 paper_manager.py status   # 状态
```

## Cron

```bash
*/30 * * * * /path/to/auto_index.sh
```

## 依赖

- Python 3.8+
- PyMuPDF >= 1.23.0
- PyYAML >= 6.0

## 相关项目

- [feishu-relay](https://github.com/crayfish-ai/feishu-relay) - 飞书通知（v3.0+）

## License

MIT
