#!/bin/bash

# Anvil 启动和清理脚本
# 用法：
#   ./start-anvil.sh          - 启动 anvil
#   ./start-anvil.sh clean    - 仅清理日志和临时文件，不启动 anvil

ANVIL_PID_FILE="$(pwd)/.anvil.pid"
ANVIL_LOG_FILE="$(pwd)/.anvil.log"
ANVIL_TMP_DIR="$HOME/.foundry/anvil/tmp"

# 清理函数
cleanup() {
  echo "[ANVIL] 清理历史日志和临时文件..."

  # 停止之前运行的 anvil（先尝试从 PID 文件）
  if [ -f "$ANVIL_PID_FILE" ]; then
    OLD_PID=$(cat "$ANVIL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
      echo "[ANVIL] 停止已运行的 anvil (PID: $OLD_PID)..."
      kill "$OLD_PID"
      sleep 1
    fi
    rm -f "$ANVIL_PID_FILE"
  fi

  # 强制停止所有 anvil 进程（以防有孤立进程）
  if pgrep -f "anvil" > /dev/null 2>&1; then
    echo "[ANVIL] 强制停止所有剩余的 anvil 进程..."
    pkill -f "anvil" || true
    sleep 1
  fi

  # 清除 anvil 日志文件
  if [ -f "$ANVIL_LOG_FILE" ]; then
    echo "[ANVIL] 删除旧日志: $ANVIL_LOG_FILE"
    rm -f "$ANVIL_LOG_FILE"
  fi

  # 清除 anvil 临时目录
  if [ -d "$ANVIL_TMP_DIR" ]; then
    echo "[ANVIL] 清除临时目录: $ANVIL_TMP_DIR"
    rm -rf "$ANVIL_TMP_DIR"
  fi

  echo "[ANVIL] 清理完成！"
}

# 检查参数
if [ "$1" = "clean" ]; then
  # 仅执行清理，不启动
  cleanup
  exit 0
fi

# 清理并启动
cleanup

echo "[ANVIL] 启动新的 anvil 实例..."

# 启动 anvil，输出重定向到日志文件
anvil --host 127.0.0.1 --port 8545 > "$ANVIL_LOG_FILE" 2>&1 &

ANVIL_PID=$!
echo $ANVIL_PID > "$ANVIL_PID_FILE"

echo "[ANVIL] Anvil started with PID: $ANVIL_PID"
echo "[ANVIL] 日志输出: $ANVIL_LOG_FILE"
echo "[ANVIL] 等待 anvil 启动..."

# 等待 anvil 完全启动（检查 RPC 是否响应）
RETRY=0
MAX_RETRIES=30

while [ $RETRY -lt $MAX_RETRIES ]; do
  if curl -s -X POST http://127.0.0.1:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
    > /dev/null 2>&1; then
    echo "[ANVIL] Anvil 已就绪！"
    break
  fi
  
  echo "[ANVIL] 等待中... ($((RETRY+1))/$MAX_RETRIES)"
  sleep 1
  RETRY=$((RETRY+1))
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  echo "[ANVIL] 错误：Anvil 启动超时"
  exit 1
fi

echo "[ANVIL] 完成！"
