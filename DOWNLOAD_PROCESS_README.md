# 科研通文献下载后处理脚本

## 脚本说明

### 1. process_ablesci_download.sh - 完整版处理脚本
**用途**: 手动或定时任务时批量处理Downloads目录的文献

**用法**:
```bash
# 处理Downloads目录中的所有科研通PDF
bash /data/disk/papers/process_ablesci_download.sh

# 处理指定文件
bash /data/disk/papers/process_ablesci_download.sh /path/to/file.pdf
```

**功能**:
- 自动识别文件名包含"科研通"或"ablesci"的PDF
- MD5去重检测
- 移动文件到 `/data/disk/papers/`
- 自动索引、重命名、提取全文、AI提炼
- 发送飞书通知
- 彩色日志输出

### 2. after_download.sh - 轻量版即时处理脚本
**用途**: 浏览器下载后立即调用（单文件处理）

**用法**:
```bash
# 处理最新下载的科研通PDF
bash /data/disk/papers/after_download.sh

# 处理指定文件
bash /data/disk/papers/after_download.sh /root/Downloads/xxx.pdf
```

**功能**:
- 轻量级，处理速度快
- 自动查找最新下载的科研通PDF
- 去重、移动、索引、通知

### 3. auto_index.sh - 定时任务脚本（已优化）
**用途**: 每30分钟自动扫描并处理

**功能**:
- 从Downloads目录移动新PDF
- 自动去重
- 索引、重命名、全文提取、AI提炼

## 使用建议

### 方案一：下载后立即处理（推荐）
在科研通下载脚本中，下载完成后调用：
```bash
bash /data/disk/papers/after_download.sh
```

### 方案二：定时任务兜底
保持现有的crontab定时任务，每30分钟扫描一次：
```bash
*/30 * * * * /data/disk/papers/auto_index.sh
```

### 方案三：手动批量处理
如果需要手动处理Downloads目录的所有文献：
```bash
bash /data/disk/papers/process_ablesci_download.sh
```

## 文件路径

| 文件 | 路径 |
|------|------|
| 完整版处理脚本 | `/data/disk/papers/process_ablesci_download.sh` |
| 轻量版即时脚本 | `/data/disk/papers/after_download.sh` |
| 定时任务脚本 | `/data/disk/papers/auto_index.sh` |
| 日志文件 | `/data/disk/papers/auto_index.log` |
| 文献目录 | `/data/disk/papers/` |
| 下载目录 | `/root/Downloads/` |

## 日志查看

```bash
# 实时查看日志
tail -f /data/disk/papers/auto_index.log

# 查看最近20行
tail -20 /data/disk/papers/auto_index.log
```
