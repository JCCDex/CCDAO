# VDR 部署快速参考

> 📖 **完整说明见** [DEPLOYMENT_STRATEGY.md](./DEPLOYMENT_STRATEGY.md)
>
> 本文档是快速命令参考。了解部署三阶段和设计原理，请阅读 DEPLOYMENT_STRATEGY.md

## 部署三个阶段

```
Stage 1: CCDAO_CREATE2          Stage 2: VDR 初始部署           Stage 3: 创建实例
(获取或部署工厂)               (部署实现+代理)                 (通过 factory)
         ↓                               ↓                              ↓
contract/CCDAO_CREATE2/      contract/CCDAO_VDR/          VDRFactory.createVDR()
script/CCDAOCreator2.s.sol    script/VDR_Deploy_Initial.s.sol
```

---

## Stage 1: CCDAO_CREATE2（如需执行）

### 测试链部署

```bash
cd ../../CCDAO_CREATE2

forge script script/CCDAOCreator2.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

**记录输出地址**:
```
✓ CCDAO_CREATE2 deployed: 0x...
```

### 生产链查询

```bash
# 工厂可能已存在，仅获取地址
cast call 0xYourCCDAO_CREATE2Address "owner()" \
  --rpc-url https://eth.llamarpc.com
```

---

## Stage 2: 初始部署（VDR 核心）

> 每个网络上执行 **一次**
> 使用 CCDAO_CREATE2 通过 CREATE2 部署，获得确定性地址

部署内容：
- ✓ VDR Implementation (CREATE2 确定性地址)
- ✓ VDRFactory Implementation (CREATE2 确定性地址)  
- ✓ VDRFactory Proxy (CREATE2 确定性地址)
- ✓ 示例 VDR 实例

### 前置条件

必须有 CCDAO_CREATE2 工厂地址（来自 Stage 1）：

```bash
# 保存工厂地址
export CCDAO_CREATE2=0x...
```

### 本地 Anvil

```bash
# 获取 CCDAO_CREATE2 地址（已部署）
export CCDAO_CREATE2=0x5FbDB2315678afccb333f8a9c45b65d30c01f173

# 运行部署（使用默认盐值）
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### Sepolia 测试网

```bash
# 设置工厂地址（从生产环境获取或已部署）
export CCDAO_CREATE2=0x...

# 运行部署
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Ethereum 主网

```bash
# 使用生产环境的 CCDAO_CREATE2 地址
export CCDAO_CREATE2=0x...

# 运行部署
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://eth.llamarpc.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --priority-gas-price 1000000000
```

### 自定义盐值（可选）

脚本使用默认盐值。如果需要自定义（例如多链部署保证地址一致）：

```bash
export CCDAO_CREATE2=0x...
export VDR_IMPL_SALT=0x0000000000000000000000000000000000000000000000000000000000000001
export VDRF_IMPL_SALT=0x0000000000000000000000000000000000000000000000000000000000000002
export VDRF_PROXY_SALT=0x0000000000000000000000000000000000000000000000000000000000000003

forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 保存关键地址

脚本执行后，**必须记录**这些地址（特别是 VDRF_FACTORY_PROXY）：

```bash
# 保存为环境变量（便于后续升级）
export VDRF_FACTORY_PROXY=0x...    # ← 最重要！升级时需要
export VDR_IMPLEMENTATION=0x...
export VDRF_IMPLEMENTATION=0x...

# 保存到 .env 文件
cat >> .env << EOF
VDRF_FACTORY_PROXY=0x...
VDR_IMPLEMENTATION=0x...
VDRF_IMPLEMENTATION=0x...
EOF
```

---

## Stage 3: 创建 VDR 实例

> 按需执行，可多次创建

### 使用 Foundry Script

```solidity
// 使用 VDRFactory 创建实例
address newVDR = VDRFactory(VDRF_FACTORY_PROXY).createVDR(
    "My VDR Name",
    ownerAddress,
    [dataManager1, dataManager2]
);
```

### 使用 ethers.js

```javascript
const factory = new ethers.Contract(
    VDRF_FACTORY_PROXY,
    VDRFactory_ABI,
    signer
);

const tx = await factory.createVDR(
    "Organization A VDR",
    ownerAddress,
    [manager1, manager2]
);

const receipt = await tx.wait();
// 从 receipt 中获取创建的实例地址
```

### 使用 cast

```bash
cast send $VDRF_FACTORY_PROXY \
  "createVDR(string,address,address[])" \
  "My VDR" \
  "0xOwnerAddress" \
  "[0xManager1,0xManager2]" \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

---

## 升级（后续版本）

> 仅当需要更新 VDR 代码时执行
> 使用 CREATE2 部署新版本，获得确定性地址

### 前置条件

必须有两个地址（来自 Stage 1 & Stage 2）：

```bash
export CCDAO_CREATE2=0x...           # 来自 Stage 1
export VDRF_FACTORY_PROXY=0x...      # 来自 Stage 2
```

### 执行升级

```bash
# 使用默认盐值
forge script script/VDR_Upgrade.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 自定义升级盐值（推荐）

每次升级应使用不同的盐值以获得不同的地址：

```bash
# 设置新盐值（例如：升级版本号递增）
export VDR_IMPL_UPGRADE_SALT=0x0000000000000000000000000000000000000000000000000000000000000010

forge script script/VDR_Upgrade.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### Testnet 升级

```bash
export CCDAO_CREATE2=0x...
export VDRF_FACTORY_PROXY=0x...
export VDR_IMPL_UPGRADE_SALT=0x...

forge script script/VDR_Upgrade.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast
```

**升级会**:
1. 通过 CREATE2 部署新的 VDR Implementation（确定性地址）
2. 调用 VDRFactory.setVDRImplementation() 更新工厂指向
3. 所有现有 VDR 实例自动获得新版本
4. VDRFactory Proxy 地址不变

---

## 常见命令速查

### 检查部署

```bash
# 检查 VDRFactory 当前版本
cast call $VDRF_FACTORY_PROXY \
  "vdrImplementationVersion()" \
  --rpc-url http://localhost:8545

# 获取 VDRFactory 所有 VDR 实例
cast call $VDRF_FACTORY_PROXY \
  "getVDRCount()" \
  --rpc-url http://localhost:8545

# 获取某个 VDR 实例信息
cast call $VDRF_FACTORY_PROXY \
  "getVDRDetails(address)" \
  "0xVDRAddress" \
  --rpc-url http://localhost:8545
```

### 环境变量设置

```bash
# 方案1：临时设置（仅当前会话）
export PRIVATE_KEY=0x...
export VDRF_FACTORY_PROXY=0x...

# 方案2：持久化（.env 文件）
echo "PRIVATE_KEY=0x..." >> .env
echo "VDRF_FACTORY_PROXY=0x..." >> .env

# 方案3：.env.local（忽略版本控制）
cat > .env.local << EOF
PRIVATE_KEY=0x...
VDRF_FACTORY_PROXY=0x...
EOF
```

---

## 故障排查

### 部署失败：insufficient balance

```bash
# 检查账户余额
cast balance $ACCOUNT_ADDRESS \
  --rpc-url http://localhost:8545

# Anvil：获取测试 ETH（自动给予足量余额）
# 确保使用 Anvil 默认账户
```

### 升级失败：setVDRImplementation 权限问题

```bash
# 检查 caller 是否是 factory owner
cast call $VDRF_FACTORY_PROXY \
  "owner()" \
  --rpc-url http://localhost:8545

# 确保使用正确的私钥（owner 地址）
```

### 创建实例失败：invalid owner address

```bash
# 检查 owner 地址有效性
cast balance 0xOwnerAddress \
  --rpc-url http://localhost:8545
```

---

## 关键概念

| 概念 | 说明 |
|-----|------|
| **VDRF_FACTORY_PROXY** | VDRFactory 的永久代理地址（升级时不变） |
| **VDR Implementation** | VDR 业务逻辑合约（升级时更新） |
| **VDR Instance** | 用户创建的 VDR 实例（有独立的 Proxy） |
| **UUPS** | 合约升级标准（VDRFactory 支持） |
| **ERC1967** | 代理标准（所有 Proxy 使用） |

---

## 更多信息

- 🔍 **完整说明**: [DEPLOYMENT_STRATEGY.md](./DEPLOYMENT_STRATEGY.md)
- 📚 **合约代码**: [src/VDRFactory.sol](./src/VDRFactory.sol)、[src/VDR.sol](./src/VDR.sol)
- ✅ **测试用例**: [test/VDRFactory.t.sol](./test/VDRFactory.t.sol)
