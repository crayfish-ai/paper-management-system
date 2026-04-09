# Paper Management System

文献管理系统 - 自动化PDF文献管理工具

## 功能特性

- 📄 **自动索引**: 扫描PDF文件，提取元数据（标题、作者、DOI等）
- 🔍 **智能搜索**: 支持标题、作者、DOI、摘要等多字段搜索
- 🏷️ **自动重命名**: 按规范格式重命名PDF文件
- 📚 **全文提取**: 提取PDF文本内容便于检索
- 🤖 **AI提炼**: 自动提取研究背景、方法、结果、结论（可选）
- 🔔 **飞书通知**: 新文献入库自动通知（可选）
- 🔄 **定时任务**: 支持cron定时自动扫描
- ⚙️ **配置外置**: 通过 config.yaml 或环境变量配置

## 安装

### 方式一：克隆项目

```bash
git clone <repo-url>
cd paper-management-system
pip install -r requirements.txt
```

### 方式二：使用 pip

```bash
pip install paper-management-system
```

## 配置

### 方式一：配置文件（推荐）

复制示例配置并修改：

```bash
cp config.example.yaml config.yaml
# 编辑 config.yaml
```

关键配置项：

```yaml
# 数据库
database:
  path: "/data/disk/papers/index.db"

# 文献目录
papers:
  dir: "/data/disk/papers"

# 下载目录（用于自动移动新文件）
downloads:
  dir: "/root/Downloads"
  keywords:
    - "科研通"
    - "ablesci"

# AI提炼（可选）
ai:
  enabled: false
  provider: "openai"
  model: "gpt-3.5-turbo"

# 通知（可选）
notification:
  enabled: false
  cmd: "/usr/local/bin/notify"  # 或 "stdout" 调试模式
```

### 方式二：环境变量

```bash
export PAPERMGR_DATABASE_PATH="/data/disk/papers/index.db"
export PAPERMGR_PAPERS_DIR="/data/disk/papers"
export PAPERMGR_DOWNLOADS_DIR="/root/Downloads"
export PAPERMGR_AI_ENABLED="false"
export PAPERMGR_NOTIFICATION_ENABLED="false"
```

### 方式三：feishu-relay 集成

配合 [feishu-relay](https://github.com/crayfish-ai/feishu-relay) v3.0+ 使用：

```yaml
notification:
  enabled: true
  cmd: "/path/to/feishu-relay/run.sh"  # 或系统中的 notify 命令
```

## 使用

### 初始化数据库

```bash
python3 paper_manager.py index
```

### 搜索文献

```bash
python3 paper_manager.py search "关键词"
```

### 自动重命名

```bash
python3 paper_manager.py rename
```

### 查看状态

```bash
python3 paper_manager.py status
```

### 手动运行自动索引

```bash
./auto_index.sh
```

## 定时任务

### Crontab 示例

```bash
# 每30分钟自动扫描
*/30 * * * * /path/to/paper-management-system/auto_index.sh >> /data/disk/papers/cron.log 2>&1

# 每天凌晨2点运行
0 2 * * * /path/to/paper-management-system/auto_index.sh >> /data/disk/papers/cron.log 2>&1
```

## AI 提炼功能

启用AI提炼功能：

1. 安装AI依赖：

```bash
pip install -r requirements.txt
pip install openai  # 或 anthropic
```

2. 配置API：

```bash
export OPENAI_API_KEY="sk-..."
```

3. 启用功能：

```yaml
# config.yaml
ai:
  enabled: true
  provider: "openai"
  model: "gpt-3.5-turbo"
```

## 数据库 Schema

当前版本：v1

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键 |
| file_hash | TEXT | MD5哈希（去重） |
| filename | TEXT | 原始文件名 |
| filepath | TEXT | 文件路径 |
| title | TEXT | 文献标题 |
| authors | TEXT | 作者 |
| doi | TEXT | DOI |
| year | INTEGER | 年份 |
| journal | TEXT | 期刊 |
| abstract | TEXT | 摘要 |
| pages | INTEGER | 页数 |
| file_size | INTEGER | 文件大小 |
| full_text | TEXT | 全文 |
| ai_summary | TEXT | AI提炼内容 |
| indexed_at | TEXT | 索引时间 |
| renamed | INTEGER | 是否已重命名 |

### Schema 版本管理

v2.0+ 支持自动迁移。数据库包含 `schema_version` 表用于追踪版本。

## 升级

```bash
# 拉取新版本
git pull

# 安装依赖
pip install -r requirements.txt

# 测试
python3 paper_manager.py status
```

详见 [CHANGELOG.md](CHANGELOG.md)。

## 项目结构

```
paper-management-system/
├── config.py              # 配置加载器
├── config.example.yaml    # 配置示例
├── paper_manager.py       # 核心管理模块
├── auto_index.sh          # 自动索引脚本（cron用）
├── extract_fulltext.py    # 全文提取
├── ai_summarize.py        # AI提炼
├── requirements.txt       # Python依赖
├── pyproject.toml         # 项目配置
├── CHANGELOG.md           # 版本历史
└── README.md
```

## 依赖

- Python 3.8+
- PyMuPDF >= 1.23.0
- PyYAML >= 6.0
- sqlite3 (内置)

可选：
- openai >= 1.0.0 (AI提炼)
- anthropic >= 0.20.0 (AI提炼)

## 相关项目

- [feishu-relay](https://github.com/crayfish-ai/feishu-relay) - 飞书统一通知服务

## License

MIT
