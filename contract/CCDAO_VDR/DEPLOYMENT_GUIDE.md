# VDR 部署指南

VDR (Virtual Data Room) 使用两个分离的脚本处理部署和升级，确保安全性和清晰的操作流程。

## 📋 脚本说明

### 1. VDR_Deploy_Initial.s.sol - 首次部署脚本

**用途**: 初始部署，部署所有必要组件

**部署内容**:
- VDR Implementation（实现合约）
- VDRFactory Implementation（工厂实现）
- VDRFactory Proxy（代理，使用 ERC1967）
- 示例 VDR 实例

**何时使用**:
- 第一次在新网络上部署
- 全新的 VDR 系统设置

**执行命令**:

```bash
# 本地 Anvil
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Sepolia 测试网
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# 以太坊主网
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url https://eth.llamarpc.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --priority-gas-price 1000000000
```

**输出示例**:
```
✓ VDR Implementation: 0x1234...
✓ VDRFactory Implementation: 0x5678...
✓ VDRFactory Proxy: 0x9abc...
✓ VDR Instance: 0xdef0...
```

**重要**: 保存所有输出地址，特别是 **VDRFactory Proxy** 地址！

---

### 2. VDR_Upgrade.s.sol - 升级脚本

**用途**: 升级 VDR 实现合约

**升级流程**:
1. 部署新的 VDR Implementation
2. 调用 `VDRFactory.setVDRImplementation()`
3. 所有现有 VDR 实例自动指向新实现

**何时使用**:
- 部署新版本（BUG 修复、功能增强）
- VDRFactory Proxy 地址保持不变
- 用户数据和状态不受影响

**执行命令**:

```bash
# 首先，编辑脚本设置 VDRFactory Proxy 地址：
# 在 VDR_Upgrade.s.sol 中找到：
#   address constant VDRF_FACTORY_PROXY = address(0); // TODO: Set this!
# 改为：
#   address constant VDRF_FACTORY_PROXY = 0x9abc...; // 从初始部署获得

# 然后运行升级脚本

# 本地 Anvil
forge script script/VDR_Upgrade.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Sepolia 测试网
forge script script/VDR_Upgrade.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# 以太坊主网
forge script script/VDR_Upgrade.s.sol \
  --rpc-url https://eth.llamarpc.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --priority-gas-price 1000000000
```

**输出示例**:
```
✓ New VDR Implementation: 0xabcd...
✓ Implementation updated successfully
Status: All existing VDR instances now use the new implementation
```

---

## 🔄 完整部署流程

### 第一次部署（完整设置）

```bash
# 1. 设置环境变量
export PRIVATE_KEY=0x...
export SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
export ETHERSCAN_API_KEY=...

# 2. 部署到 Sepolia 测试网
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast

# 3. 保存输出地址
# VDRFactory Proxy: 0x9abc...
# VDR Implementation: 0x1234...
```

### 升级到新版本

```bash
# 1. 编辑 VDR_Upgrade.s.sol，设置 VDRF_FACTORY_PROXY 地址

# 2. 部署新实现
forge script script/VDR_Upgrade.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast

# 3. 验证升级
# 查看新的 VDR Implementation 地址
# 所有现有 VDR 实例自动使用新实现
```

---

## ⚠️ 重要注意事项

### 初始部署 (VDR_Deploy_Initial.s.sol)

✅ **应该做**:
- 第一次在新网络部署
- 保存所有输出地址
- VDRFactory Proxy 地址最重要

❌ **不应该做**:
- 再次运行相同脚本（会创建新的代理）
- 丢失 VDRFactory Proxy 地址

### 升级 (VDR_Upgrade.s.sol)

✅ **应该做**:
- 设置正确的 VDRF_FACTORY_PROXY 地址
- 确保调用者是 factory owner
- 新实现版本号必须更高

❌ **不应该做**:
- 修改 VDRFactory Proxy 地址
- 使用非 owner 账户运行
- 部署版本号更低的实现

---

## 🔐 权限要求

| 操作 | 脚本 | 权限要求 |
|------|------|--------|
| 初始部署 | VDR_Deploy_Initial.s.sol | 部署者自动成为 factory owner |
| 升级 | VDR_Upgrade.s.sol | 必须是 factory owner |
| 创建 VDR 实例 | 任何人可以调用 `factory.createVDR()` | 无 |

---

## 📊 地址管理

### 初始部署后保存的地址

```
Network: Sepolia
Date: 2024-01-20

VDRFactory Proxy: 0x9abc...
  └─ Owner: 0x1234...
  
VDR Implementation v1.0.0: 0x1234...
VDRFactory Implementation: 0x5678...

Default VDR Instance: 0xdef0...
```

### 升级后的地址变化

```
升级前：
VDR Implementation v1.0.0: 0x1234...

升级后：
VDR Implementation v1.1.0: 0xabcd...  ← 新地址
VDRFactory Proxy: 0x9abc...           ← 不变！
```

---

## 🧪 测试部署

在实际部署前，始终先在本地测试：

```bash
# 使用 Anvil 测试首次部署
anvil

# 另一个终端
forge script script/VDR_Deploy_Initial.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --non-interactive

# 测试升级
forge script script/VDR_Upgrade.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --non-interactive
```

---

## 常见问题

**Q: 升级后旧的 VDR 实例会丢失数据吗?**
A: 不会。VDR 实例使用代理模式，数据存储在代理中，新实现会读取所有现有状态。

**Q: 为什么需要两个脚本？**
A: 防止意外重新部署代理（会导致状态丢失）。分离脚本使意图清晰，操作更安全。

**Q: 如何回滚升级？**
A: 部署上一个版本的实现，再次调用 `setVDRImplementation()`。

**Q: 能否更改 VDRFactory 的 owner？**
A: 可以，通过调用 `transferOwnership()`。升级脚本需要在 owner 下执行。

