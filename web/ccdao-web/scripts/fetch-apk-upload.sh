#!/bin/bash
# APK 自动获取并上传到远程服务器（纯 Shell 版本）
#
# 环境变量（或在 .env 文件中配置）：
#   GITLAB_TOKEN    - GitLab Private Token（必填）
#   GITLAB_URL      - GitLab 地址，默认 http://192.168.66.246
#   REMOTE_HOST     - 网站服务器 IP 或主机名（必填）
#   REMOTE_USER     - SSH 用户名（留空则走 ~/.ssh/config）
#   REMOTE_PORT     - SSH 端口，默认 22
#   REMOTE_DIR      - 远程目标目录（必填）
#   SSH_KEY         - SSH 私钥路径（可选）
#   VERSION_FILE    - 本地版本记录文件，默认 ~/.apk_latest_version

set -euo pipefail

# ===== 获取脚本目录 =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ===== 防止并发执行（文件锁，放在脚本目录） =====
LOCK_FILE="$SCRIPT_DIR/fetch-apk-upload.lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "⚠️  上次任务还在运行 (PID: $LOCK_PID)，跳过本次执行"
        exit 0
    else
        echo "🧹 清理残留锁文件 (PID: $LOCK_PID 已不存在)"
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; rm -rf "$TEMP_DIR"' EXIT

# ===== 读取 .env =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# ===== 默认值 =====
GITLAB_URL="${GITLAB_URL:-http://192.168.66.246}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_PORT="${REMOTE_PORT:-22}"
PROJECT_ID="chtian%2Fwodecards"
BRANCH="apk"
APK_DIR="apk/ccdao/release"
VERSION_FILE="${VERSION_FILE:-$HOME/.apk_latest_version}"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

# ===== 前置检查 =====
for cmd in curl jq unzip rsync ssh; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少依赖: $cmd，请先安装"; exit 1; }
done

[ -z "${GITLAB_TOKEN:-}" ] && { echo "❌ 请设置 GITLAB_TOKEN"; exit 1; }
[ -z "${REMOTE_HOST:-}" ] && { echo "❌ 请设置 REMOTE_HOST"; exit 1; }
[ -z "${REMOTE_DIR:-}" ]   && { echo "❌ 请设置 REMOTE_DIR"; exit 1; }

# ===== SSH 选项 =====
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
[ -n "${SSH_KEY:-}" ] && SSH_OPTS="$SSH_OPTS -i $SSH_KEY"
[ "$REMOTE_PORT" != "22" ] && SSH_OPTS="$SSH_OPTS -p $REMOTE_PORT"

# ===== GitLab API 封装 =====
gitlab_api() {
    curl -sS --fail --max-time 60 \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$@"
}

# ===== 1. 获取最新版本 =====
echo "🔍 检查 APK 更新..."

VERSIONS_JSON=$(gitlab_api "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/tree?path=${APK_DIR}&ref=${BRANCH}&per_page=100")

# 过滤目录类型，按版本号降序排序
LATEST_VERSION=$(echo "$VERSIONS_JSON" | jq -r '[.[] | select(.type=="tree") | .name] | sort_by(split(".") | map(tonumber)) | reverse | .[0]')

[ -z "$LATEST_VERSION" ] && { echo "❌ 未找到任何版本"; exit 1; }
echo "📦 最新版本: $LATEST_VERSION"

# ===== 2. 与本地版本对比 =====
LOCAL_VERSION=""
[ -f "$VERSION_FILE" ] && LOCAL_VERSION=$(cat "$VERSION_FILE")

if [ "$LOCAL_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ 已是最新版本: $LATEST_VERSION，无需更新"
    exit 0
fi

echo "🔄 发现更新: ${LOCAL_VERSION:-无} → $LATEST_VERSION"

# ===== 3. 下载并解压 =====
FILES_JSON=$(gitlab_api "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/tree?path=${APK_DIR}/${LATEST_VERSION}&ref=${BRANCH}")

FILE_NAMES=$(echo "$FILES_JSON" | jq -r '.[].name')
echo "📄 版本文件: $(echo $FILE_NAMES | tr '\n' ' ')"

for FILE in $FILE_NAMES; do
    REMOTE_PATH="${APK_DIR}/${LATEST_VERSION}/${FILE}"
    ENCODED_PATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$REMOTE_PATH', safe=''))" 2>/dev/null || echo "$REMOTE_PATH")
    echo "⬇️  下载: $FILE"
    gitlab_api "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/repository/files/${ENCODED_PATH}/raw?ref=${BRANCH}" \
        -o "$TEMP_DIR/$FILE"

    # 解压 zip/tar.gz
    case "$FILE" in
        *.zip)
            echo "📦 解压: $FILE"
            unzip -o -q "$TEMP_DIR/$FILE" -d "$TEMP_DIR"
            rm "$TEMP_DIR/$FILE"
            ;;
        *.tar.gz|*.tgz)
            echo "📦 解压: $FILE"
            tar -xzf "$TEMP_DIR/$FILE" -C "$TEMP_DIR"
            rm "$TEMP_DIR/$FILE"
            ;;
    esac
done

# 清理 macOS 垃圾
rm -rf "$TEMP_DIR/__MACOSX"
find "$TEMP_DIR" -name ".DS_Store" -delete

# 如果解压后只有一个子目录，提取其内容（扁平化）
SUBDIRS=$(find "$TEMP_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l)
echo "📂 检测到 $SUBDIRS 个子目录"
if [ "$SUBDIRS" -eq 1 ]; then
    SUBDIR=$(find "$TEMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)
    echo "📁 扁平化: $(basename "$SUBDIR")/"
    # 移动所有文件（包括隐藏文件）
    find "$SUBDIR" -mindepth 1 -maxdepth 1 -exec mv {} "$TEMP_DIR"/ \;
    rm -rf "$SUBDIR"
else
    echo "⚠️  不扁平化（有 $SUBDIRS 个子目录）"
fi

# 重命名 checksums 文件（必须在扁平化之后）
CHECKSUM_FILE=$(find "$TEMP_DIR" -maxdepth 1 -name "checksums-*.txt" | head -1)
if [ -n "$CHECKSUM_FILE" ]; then
    mv "$CHECKSUM_FILE" "$TEMP_DIR/checksums.txt"
    echo "📝 重命名: $(basename "$CHECKSUM_FILE") → checksums.txt"
fi

# 解析 checksums.txt 文件（过滤注释行和空行）
CHECKSUMS_CONTENT=""
if [ -f "$TEMP_DIR/checksums.txt" ]; then
    CHECKSUMS_CONTENT=$(grep -E '^[^#].*=' "$TEMP_DIR/checksums.txt" | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# 生成 version.json（包含 checksums.txt）
FILES_INFO=$(find "$TEMP_DIR" -maxdepth 1 -type f ! -name "version.json" -exec sh -c '
    for f; do
        size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
        printf "{\"name\":\"%s\",\"size\":%s}\n" "$(basename "$f")" "$size"
    done
' _ {} + | jq -s .)

# 构建 checksums JSON（如果有）
CHECKSUMS_JSON="null"
if [ -n "$CHECKSUMS_CONTENT" ]; then
    CHECKSUMS_JSON=$(echo "$CHECKSUMS_CONTENT" | awk 'BEGIN{OFS=""; printf "{"} {
        idx=index($0,"=");
        if(idx>0){
            key=substr($0,1,idx-1);
            val=substr($0,idx+1);
            gsub(/^[ \t]+|[ \t]+$/,"",key);
            gsub(/^[ \t]+|[ \t]+$/,"",val);
            if(NR>1) printf ",";
            printf "\"%s\":\"%s\"",key,val;
        }
    } END{printf "}"}')
fi

cat > "$TEMP_DIR/version.json" <<EOJSON
{
  "version": "$LATEST_VERSION",
  "updateTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "files": $FILES_INFO,
  "checksums": $CHECKSUMS_JSON
}
EOJSON

echo "✅ 下载完成，文件列表:"
ls -lh "$TEMP_DIR"/

# ===== 4. 上传到远程服务器 =====
echo ""
# 构建远程目标
#   设了 REMOTE_USER → user@host
#   没设              → 直接用服务器名，走 ~/.ssh/config
if [ -n "${REMOTE_USER:-}" ]; then
    REMOTE_TARGET="${REMOTE_USER}@${REMOTE_HOST}"
else
    REMOTE_TARGET="${REMOTE_HOST}"
fi

echo "📤 上传到 ${REMOTE_TARGET}:${REMOTE_DIR}"

# 创建远程目录
ssh $SSH_OPTS "${REMOTE_TARGET}" "mkdir -p ${REMOTE_DIR}"

# rsync 先上传到临时目录
TEMP_REMOTE_DIR="${REMOTE_DIR}.tmp.$$"
echo "📤 上传到临时目录: ${TEMP_REMOTE_DIR}"
ssh $SSH_OPTS "${REMOTE_TARGET}" "mkdir -p ${TEMP_REMOTE_DIR}"
RSYNC_SSH="ssh $SSH_OPTS"
rsync -rltDv --progress -e "$RSYNC_SSH" "$TEMP_DIR/" "${REMOTE_TARGET}:${TEMP_REMOTE_DIR}/"

# 将临时目录里的文件移动到正式目录（不删除正式目录已有文件）
ssh $SSH_OPTS "${REMOTE_TARGET}" "mkdir -p ${REMOTE_DIR} && mv ${TEMP_REMOTE_DIR}/* ${REMOTE_DIR}/ && rmdir ${TEMP_REMOTE_DIR}"

echo "✅ 已切换到正式目录: ${REMOTE_DIR}"

# ===== 5. 记录版本号 =====
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "📝 版本已记录: $VERSION_FILE → $LATEST_VERSION"
echo "✅ 全部完成！"
