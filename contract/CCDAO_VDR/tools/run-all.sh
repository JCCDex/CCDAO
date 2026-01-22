#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VDR_DIR="$(dirname "$SCRIPT_DIR")"
CREATE2_DIR="$(dirname "$VDR_DIR")/CCDAO_CREATE2"

echo "================================================"
echo "VDR 合约部署测试"
echo "================================================"
echo ""

# 检查 Anvil 是否运行
if ! curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  > /dev/null 2>&1; then
  echo "[ERROR] Anvil 未运行！"
  echo "请先启动 Anvil: ./start-anvil.sh"
  exit 1
fi

echo "[OK] Anvil 已就绪"
echo ""

# ========== 第 1 步：编译 CREATE2 合约 ==========
echo "[1/3] 编译 CCDAO_CREATE2 合约..."
cd "$CREATE2_DIR"
forge build 2>&1 | grep -E "Compiling|Finished|error" || true
echo ""

# ========== 第 2 步：编译 VDR 合约 ==========
echo "[2/3] 编译 CCDAO_VDR 合约..."
cd "$VDR_DIR"
forge build 2>&1 | grep -E "Compiling|Finished|error" || true
echo ""

# ========== 第 3 步：运行部署脚本 ==========
echo "[3/4] 运行部署脚本..."
cd "$SCRIPT_DIR"

# 检查 package.json 中是否有 deploy 命令
if grep -q '"deploy"' package.json 2>/dev/null; then
  npm run deploy
else
  # 直接运行 node
  node scripts/deploy.js
fi

echo ""

# ========== 第 4 步：运行集成测试 ==========
echo "[4/4] 运行集成测试..."
cd "$SCRIPT_DIR"

# 检查 package.json 中是否有 test 命令
if grep -q '"test"' package.json 2>/dev/null; then
  npm test
else
  # 直接运行测试文件
  node test/integration.test.js
fi

echo ""
echo "================================================"
echo "测试完成！"
echo "================================================"
echo ""

# 显示部署结果摘要
if [ -f "artifacts/deployment.json" ]; then
  echo "部署地址：" 
  cat artifacts/deployment.json | jq .
fi
