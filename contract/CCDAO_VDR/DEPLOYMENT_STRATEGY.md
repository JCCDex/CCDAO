# VDR 部署策略

## 概述

VDR 系统的部署分为三个阶段，这样设计是为了分离关注点，使每个阶段职责清晰：

```
Stage 1 (准备阶段)      Stage 2 (VDR部署)           Stage 3 (创建实例)
     ↓                      ↓                           ↓
CCDAO_CREATE2        VDR核心合约                   创建VDR实例
  (工厂合约)          (实现+代理)            (通过VDRFactory)
     ↓                      ↓                           ↓
部署或获取地址    部署实现+代理                    创建多个实例
测试链：部署         支持升级(UUPS)        VDR Instance 1..N
生产链：获取地址    一次性操作              (由factory创建)
```

## 部署阶段详解

### Stage 1: CCDAO_CREATE2 部署工厂

**目的**: 使用 CREATE2 实现确定性部署（可选，主要为测试链）

**何时执行**:
- 测试链（Anvil、Sepolia）：**必须执行**
- 生产链（Mainnet）：**仅获取已部署地址**（工厂可能已存在）

**具体操作**:

```bash
# 测试链部署
cd contract/CCDAO_CREATE2
forge script script/CCDAOCreator2.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast

# 生产链（仅查询）
cast call 0xYourCCDAO_CREATE2Address "owner()" \
  --rpc-url https://eth.llamarpc.com
```

**部署后获得**:
- CCDAO_CREATE2 合约地址
- 记录下来用于 Stage 2

**为什么需要 Stage 1?**
- CREATE2 可生成确定性地址（相同部署参数 = 相同地址）
- 便于多链部署时保持一致性
- 可选：如果工厂已存在，只需获取地址即可

---

### Stage 2: VDR 核心部署（只执行一次）

**目的**: 部署 VDR 系统的核心基础设施

**执行时机**: 每个网络上执行 **一次**

**部署的合约**:

| 合约 | 作用 | 可升级 |
|-----|------|------|
| VDR Implementation | VDR 业务逻辑 | ✅ 可升级 |
| VDRFactory Implementation | 工厂业务逻辑 | ✅ 可升级 |
| VDRFactory Proxy (ERC1967) | VDRFactory 代理 | ✅ UUPS |

**部署架构**:

```
VDRFactory Proxy (ERC1967)
        ↓
VDRFactory Implementation v1.0.0
        ↓
  (指向VDR Implementation v1.0.0)
        ↓
VDR Implementation v1.0.0
```

**执行命令**:

```bash
# Local Anvil
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Sepolia Testnet
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast

# Production
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://eth.llamarpc.com \
  --private-key $PRIVATE_KEY \
  --broadcast
```

**重要记录**:

部署后会输出关键地址，**必须保存**:

```
VDR_IMPLEMENTATION=0x...
VDRF_IMPLEMENTATION=0x...
VDRF_FACTORY_PROXY=0x...      # ← 最重要，升级时需要
```

**部署后的状态**:
- VDRFactory Proxy 地址固定不变（后续不会重新部署）
- VDR Implementation 地址可变（升级时部署新版本）
- VDRFactory Implementation 地址可变（升级时部署新版本）

---

### Stage 3: 创建 VDR 实例（按需执行）

**目的**: 为应用创建 VDR 实例

**执行时机**: 应用需要新 VDR 时，可随时执行（多次）

**创建方式**:

```solidity
// 通过 VDRFactory 创建
address newVDR = VDRFactory(VDRF_FACTORY_PROXY).createVDR(
    "My VDR Name",
    ownerAddress,
    [dataManager1, dataManager2, ...]
);
```

**关键特点**:
- 每次创建都生成新的 VDR Proxy（ERC1967）
- 多个 VDR 实例共享同一个 Implementation
- 创建完全由 VDRFactory 管理，无需手动部署

**示例流程**:

```javascript
// 使用 ethers.js
const factory = new ethers.Contract(
    VDRF_FACTORY_PROXY,
    VDRFactory_ABI,
    signer
);

// 创建第一个实例
const tx1 = await factory.createVDR(
    "Organization A VDR",
    ownerAddressA,
    [manager1, manager2]
);
const receipt1 = await tx1.wait();
// 从 receipt 中获取 newVDR 地址

// 创建第二个实例
const tx2 = await factory.createVDR(
    "Organization B VDR",
    ownerAddressB,
    [manager3, manager4]
);
const receipt2 = await tx2.wait();
```

---

## 升级策略

### VDR Implementation 升级

当 VDR 合约代码需要更新时：

```bash
# 步骤1: 部署新 VDR Implementation
forge script script/VDR_Upgrade.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast

# 脚本会自动:
# 1. 部署新的 VDR Implementation
# 2. 调用 VDRFactory.setVDRImplementation()
# 3. 所有现有 VDR 实例自动指向新实现
```

**升级后的状态**:
```
VDRFactory Proxy (地址不变) ← 重要！
        ↓
VDRFactory Implementation v1.0.1 (新版本)
        ↓
  (指向VDR Implementation v1.0.1)
        ↓
VDR Implementation v1.0.1 (新版本)
        ↓
所有现有 VDR 实例 (自动使用新实现)
```

**升级的优势**:
- VDRFactory Proxy 地址永不改变（客户端无需更新地址）
- 所有现有 VDR 实例自动升级（一次性）
- 新创建的 VDR 实例使用最新版本

---

## 为什么需要三个阶段？

### 关注点分离

| 阶段 | 工作 | 频率 |
|-----|-----|-----|
| Stage 1 | 部署通用工厂 | 每网络一次（或无需执行） |
| Stage 2 | 部署 VDR 系统 | 每网络一次 |
| Stage 3 | 创建应用实例 | 按需多次 |

### 生产 vs 测试的差异

**测试链**:
```
Stage 1: 部署 CCDAO_CREATE2（确保地址一致）
Stage 2: 部署 VDR 核心
Stage 3: 创建测试实例
```

**生产链**:
```
Stage 1: 仅获取已存在的 CCDAO_CREATE2 地址
Stage 2: 部署 VDR 核心（首次）
   或
Stage 2+: 仅执行升级（后续）
Stage 3: 按需创建 VDR 实例
```

### 安全性

分离部署脚本可以：
- 防止误操作（如重新部署 Proxy）
- 清晰的职责边界
- 易于审计和追踪

---

## 常见问题

### Q1: 为什么不直接部署 VDRFactory，而是需要 CCDAO_CREATE2?

A: 
- CCDAO_CREATE2 提供确定性部署（CREATE2）
- 多网络间保持一致的地址
- 测试链可以完全重现生产链的地址
- 生产链已部署，测试链只需复用地址

### Q2: VDRFactory Proxy 为什么不能升级?

A:
- VDRFactory Proxy 使用 ERC1967，**可以升级**
- 升级脚本（VDR_Upgrade.s.sol）不重新部署 Proxy
- 只更新指向的 Implementation（VDRFactory Implementation）
- 这样地址保持稳定，客户端无需更新

### Q3: 创建的多个 VDR 实例会重复部署吗?

A:
- 每个 VDR 实例都有自己的 Proxy（ERC1967）
- 但所有实例共享同一个 Implementation
- 升级 Implementation 时，所有实例自动获得新版本
- 节省部署成本，简化管理

### Q4: 如果需要修改 VDRFactory 代码怎么办?

A:
- 部署新的 VDRFactory Implementation
- 通过 VDRFactory Proxy 升级（使用 UUPS）
- 仍然使用 VDR_Upgrade.s.sol 脚本（或修改为 Factory_Upgrade.s.sol）

### Q5: VDRFactory 能否由 CCDAO_CREATE2 工厂创建?

A:
- 可以，但当前脚本是直接部署
- 如果需要确定性地址，可修改脚本使用 CCDAO_CREATE2 的 `deploy()` 方法
- 目前简单起见，直接部署 Proxy

---

## 检查清单

### Stage 1 后
- [ ] CCDAO_CREATE2 已部署或获得地址
- [ ] 地址已保存

### Stage 2 后
- [ ] VDR Implementation 已部署
- [ ] VDRFactory Implementation 已部署
- [ ] VDRFactory Proxy 已部署并初始化
- [ ] 三个地址已保存在环境变量或配置文件
- [ ] VDRFactory Proxy 地址特别重要（升级时需要）

### Stage 3 后
- [ ] 已通过 VDRFactory.createVDR() 创建实例
- [ ] 实例地址已记录

### 升级时
- [ ] 有 VDRFactory Proxy 地址（来自 Stage 2）
- [ ] 已设置 VDRF_FACTORY_PROXY 环境变量
- [ ] 运行升级脚本
- [ ] 验证新实现已激活
