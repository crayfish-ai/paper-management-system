# Migration Guide: v1.x → v2.0.0

## Overview

v2.0.0 introduces a centralized configuration system, database schema versioning, and notification adapter pattern. This guide helps you upgrade from v1.x.

## Breaking Changes

1. **Configuration method**: Paths are no longer hardcoded in scripts
2. **Database schema**: New `schema_version` table added
3. **Notification**: Requires config update (no more hardcoded paths)

## Step-by-Step Upgrade

### 1. Backup

```bash
# Backup database
cp /data/disk/papers/index.db /data/disk/papers/index.db.v1.backup

# Backup current scripts
cp paper_manager.py paper_manager.py.bak
cp auto_index.sh auto_index.sh.bak
cp ai_summarize.py ai_summarize.py.bak
```

### 2. Install Dependencies

```bash
pip install PyMuPDF pyyaml
```

### 3. Create Configuration

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
  enabled: false
  provider: "openai"
  model: "gpt-3.5-turbo"

notification:
  enabled: false
  cmd: ""
```

Adjust paths to match your current setup.

### 4. Update AI Summarization

If you were using AI summarization:

```bash
pip install openai
```

Then in `config.yaml`:

```yaml
ai:
  enabled: true
  provider: "openai"
  model: "gpt-3.5-turbo"

notification:
  enabled: true
  cmd: "/path/to/feishu-relay/run.sh"
```

### 5. Test

```bash
python3 paper_manager.py status
./auto_index.sh
```

### 6. Update Cron Jobs

No changes needed if using the same paths. If you changed paths in config, ensure cron uses the correct working directory.

## Environment Variables

All config keys can be set via environment variables with `PAPERMGR_` prefix:

| Config Key | Environment Variable |
|------------|---------------------|
| database.path | PAPERMGR_DATABASE_PATH |
| papers.dir | PAPERMGR_PAPERS_DIR |
| downloads.dir | PAPERMGR_DOWNLOADS_DIR |
| logging.path | PAPERMGR_LOGGING_PATH |
| ai.enabled | PAPERMGR_AI_ENABLED |
| notification.enabled | PAPERMGR_NOTIFICATION_ENABLED |
| notification.cmd | PAPERMGR_NOTIFICATION_CMD |

## Rollback

If something goes wrong:

```bash
# Restore v1 scripts
cp paper_manager.py.bak paper_manager.py
cp auto_index.sh.bak auto_index.sh
cp ai_summarize.py.bak ai_summarize.py

# Restore database
cp /data/disk/papers/index.db.v1.backup /data/disk/papers/index.db
```

## What's New

See [CHANGELOG.md](CHANGELOG.md) for full details.
