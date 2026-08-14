# APK 自动更新脚本

## 概述

提供两个脚本，从内网 GitLab 自动获取最新版本 APK：

| 脚本                  | 适用场景                         | 依赖            |
| --------------------- | -------------------------------- | --------------- |
| `fetch-apk.js`        | 脚本和网站在**同一台机器**       | Node.js + axios |
| `fetch-apk-upload.sh` | 脚本在一台机器，网站在**另一台** | curl, jq, rsync |

---

## 方案一：fetch-apk-upload.sh（推荐）

**场景**：内网服务器定时拉取 → 上传到网站服务器

### 前置条件

```bash
# 安装依赖
apt-get install -y curl jq unzip rsync   # Ubuntu/Debian
# 或
yum install -y curl jq unzip rsync       # CentOS/RHEL

# 配置 SSH 免密登录到网站服务器
ssh-keygen -t rsa -b 4096
ssh-copy-id -i ~/.ssh/id_rsa.pub root@网站服务器IP
```

### 配置

创建 `.env` 文件：

```bash
# GitLab 配置
GITLAB_TOKEN=***

# 远程服务器配置（网站服务器）
REMOTE_HOST=192.168.x.x          # 网站服务器 IP 或主机名
REMOTE_USER=root                  # SSH 用户名
REMOTE_PORT=22                    # SSH 端口
REMOTE_DIR=/path/to/public/apk    # 目标目录

# SSH 私钥（可选）
# SSH_KEY=***
```

### 运行

```bash
# 手动测试
chmod +x scripts/fetch-apk-upload.sh
./scripts/fetch-apk-upload.sh
```

### 定时执行

```bash
crontab -e

# 每小时检查一次
0 * * * * /path/to/ccdao-web/scripts/fetch-apk-upload.sh >> /path/to/logs/apk.log 2>&1
```

---

## 方案二：fetch-apk.js

**场景**：脚本和网站在同一台机器

### 前置条件

```bash
# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs unzip

# 安装依赖
npm install axios
```

### 配置

在 `.env` 文件中添加：

```bash
GITLAB_TOKEN=***
```

### 运行

```bash
node scripts/fetch-apk.js
```

### 定时执行

```bash
crontab -e

# 每小时检查一次
0 * * * * cd /path/to/ccdao-web && node scripts/fetch-apk.js >> logs/apk-update.log 2>&1
```

---

## 工作原理

两个脚本逻辑相同：

1. 从 GitLab 获取 `apk/ccdao/release` 目录下的所有版本
2. 按版本号排序，找到最新版本
3. 与本地记录对比（已有版本则跳过）
4. 下载该版本目录下的所有文件
5. 如果是压缩包（.zip/.tar.gz），解压并扁平化
6. 清理 macOS 垃圾文件（`__MACOSX`、`.DS_Store`）
7. 重命名 checksums 文件为 `checksums.txt`
8. 生成 `version.json` 记录版本信息

**区别**：

- `.js`：写入本地 `public/` 目录
- `.sh`：用 rsync 上传到远程服务器

---

## 输出目录结构

```
public/apk/
├── version.json          # 版本信息
├── ccdao.apk             # APK 文件
├── ccdao.apk.hash        # Hash 文件
└── checksums.txt         # 校验和
```

### version.json 格式

```json
{
  "version": "1.0.0",
  "updateTime": "2026-08-14T03:00:00Z",
  "files": [
    { "name": "ccdao.apk", "size": 12345678 },
    { "name": "ccdao.apk.hash", "size": 64 }
  ]
}
```

---

## 前端集成

```javascript
fetch("/apk/version.json")
  .then((res) => res.json())
  .then((data) => {
    console.log("当前版本:", data.version);
    console.log("更新时间:", data.updateTime);
    console.log("文件列表:", data.files);
  });
```

---

## 故障排查

### Token 无效

```bash
# 测试 Token
curl -H "PRIVATE-TOKEN: *** http://192.168.66.246/api/v4/user
```

### SSH 连接失败

```bash
# 测试 SSH
ssh -v root@网站服务器IP

# 检查防火墙
ufw status           # Ubuntu
firewall-cmd --list-all  # CentOS
```

### 查看日志

```bash
tail -f /path/to/logs/apk.log
```

---

## 注意事项

- 版本号格式应为语义化版本（如 `0.0.1`、`1.2.3`）
- 每次更新会覆盖之前的文件
- 建议配合日志记录使用
- 确保服务器安装了 `unzip`（用于解压）
