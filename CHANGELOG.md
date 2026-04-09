# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-04-09

### Added
- **Configuration system**: Unified `config.yaml` configuration with environment variable override support (`PAPERMGR_*` prefix)
- **Schema versioning**: Database now supports schema version tracking and migrations
- **Notification adapter**: Configurable notification system with support for:
  - External command (`/usr/local/bin/notify`)
  - Stdout mode for debugging
  - Complete disable option
- **Requirements.txt**: Standard Python dependency file
- **pyproject.toml**: Modern Python project configuration
- **Example config**: `config.example.yaml` for easy setup

### Changed
- **paper_manager.py**: Now uses `config.py` for all paths instead of hardcoded values
- **auto_index.sh**: Now reads configuration from config system
- **ai_summarize.py**: Complete rewrite with notification adapter and config support

### Deprecated
- Hardcoded paths in scripts (DB_PATH, PAPERS_DIR, etc.)

### Fixed
- AI summarization now properly handles missing metadata fields
- Notification system no longer requires manual path editing

## [1.0.0] - 2026-04-08

### Added
- Initial release
- PDF metadata extraction (title, authors, DOI, year, journal, abstract)
- SQLite database indexing with deduplication
- Automatic file renaming
- Full-text extraction
- AI-powered literature summarization
- Basic search functionality
- Cron job support via auto_index.sh
- Feishu notification support (via feishu-relay)

---

## Migration Guide

### Upgrading from v1.x to v2.0.0

#### 1. Backup your data
```bash
cp /data/disk/papers/index.db /data/disk/papers/index.db.backup
```

#### 2. Update configuration
Create `config.yaml` in the project directory:
```yaml
database:
  path: "/data/disk/papers/index.db"

papers:
  dir: "/data/disk/papers"

downloads:
  dir: "/root/Downloads"
  keywords:
    - "科研通"
    - "ablesci"

logging:
  path: "/data/disk/papers/auto_index.log"

ai:
  enabled: false  # Set to true to enable AI summarization
  provider: "openai"
  model: "gpt-3.5-turbo"

notification:
  enabled: false  # Set to true to enable notifications
  cmd: "/usr/local/bin/notify"  # or "stdout" for debug
```

Or use environment variables:
```bash
export PAPERMGR_DATABASE_PATH="/data/disk/papers/index.db"
export PAPERMGR_PAPERS_DIR="/data/disk/papers"
export PAPERMGR_AI_ENABLED="false"
export PAPERMGR_NOTIFICATION_ENABLED="false"
```

#### 3. Database migration
The v2.0.0 includes automatic schema migration. On first run, it will:
1. Create `schema_version` table
2. Apply v1 schema if not already applied
3. Future migrations will be applied automatically

#### 4. Test the upgrade
```bash
python3 paper_manager.py status
./auto_index.sh
```
