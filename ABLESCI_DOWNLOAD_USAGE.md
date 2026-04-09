# 科研通文献下载后自动处理 - 使用说明

## 快速使用

### 在浏览器自动化脚本中调用

当你使用浏览器自动化完成科研通文献下载后，立即执行以下命令：

```bash
bash /data/disk/papers/after_download.sh
```

### 完整流程示例

```bash
# 1. 打开科研通详情页
browser open https://www.ablesci.com/assist/detail?id=xxx

# 2. 点击采纳文件（手工或自动化）
# ... 自动化点击流程 ...

# 3. 点击下载链接
browser act click ref=xxx

# 4. 等待下载完成后，立即调用处理脚本
bash /data/disk/papers/after_download.sh
```

## 脚本说明

### after_download.sh - 下载后立即处理（推荐）

**位置**: `/data/disk/papers/after_download.sh`

**功能**:
- 自动查找 `/root/Downloads/` 目录最新的科研通PDF
- 等待文件下载完成（检测文件大小）
- MD5去重检测
- 移动到 `/data/disk/papers/`
- 自动索引、重命名、提取全文、AI提炼
- 发送飞书通知

**使用方法**:
```bash
# 自动查找最新下载的文件
bash /data/disk/papers/after_download.sh

# 或指定文件路径
bash /data/disk/papers/after_download.sh /root/Downloads/xxx.pdf
```

## 处理流程

```
┌─────────────────┐     ┌─────────────────────┐     ┌─────────────────┐
│  浏览器下载PDF   │ ──▶ │ after_download.sh   │ ──▶ │ /data/disk/papers│
│  (科研通文献)    │     │  - 等待下载完成      │     │  (自动索引入库)   │
└─────────────────┘     │  - MD5去重          │     └─────────────────┘
                        │  - 移动文件          │              │
                        │  - 索引+重命名       │              ▼
                        │  - 全文提取          │     ┌─────────────────┐
                        │  - AI提炼            │     │  飞书通知        │
                        │  - 飞书通知          │     │  (新文献入库)    │
                        └─────────────────────┘     └─────────────────┘
```

## 日志查看

```bash
# 实时查看处理日志
tail -f /data/disk/papers/auto_index.log

# 查看最近处理记录
tail -50 /data/disk/papers/auto_index.log | grep -E "(文献下载后处理|处理文件|处理完成)"
```

## 注意事项

1. **调用时机**: 在浏览器点击下载链接后，等待2-3秒再调用脚本
2. **文件识别**: 脚本只处理文件名包含"科研通"或"ablesci"的PDF
3. **去重机制**: 通过MD5 hash比对，避免重复入库
4. **失败处理**: 如果即时处理失败，定时任务（每30分钟）会兜底处理

## 备选方案

如果即时调用不方便，可以依赖定时任务：
```bash
# 查看定时任务
crontab -l

# 手动触发定时任务
bash /data/disk/papers/auto_index.sh
```
