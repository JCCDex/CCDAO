# CCDAOCreator2 - CREATE2 确定性部署与资产恢复

一个生产级别的 Solidity 合约，利用 CREATE2 操作码进行确定性合约部署，并配备全面的机制来恢复意外转入的代币。

## 概述

CCDAOCreator2 能够在特定地址进行可预测的合约部署，同时提供针对意外代币转账的实际防御。这在工厂模式、跨链部署以及需要提前确定部署地址的去中心化自治组织(DAO)基础设施中特别有用。

## 主要特性

### 核心部署特性
- **确定性部署**: 使用 CREATE2 操作码在可预测的地址部署合约
- **地址预测**: 在实际部署前计算部署地址
- **ETH 支持**: 在合约部署期间转发 ETH 用于初始化
- **灵活的字节码**: 部署任意有效的合约字节码

### 资产保护特性
- **ETH 拒绝**: 通过 fallback 自动拒绝所有传入的 ETH 转账
- **ERC721 防御**: 通过 `onERC721Received` 钩子拒绝标准 ERC721 代币；为不兼容的实现提供恢复机制
- **ERC20 恢复**: 为 ERC20 代币提供所有者控制的提现机制（由于缺少接收器钩子，无法拒绝）

## 合约函数

### 部署函数

#### `deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address)`

使用 CREATE2 进行确定性地址计算来部署合约。

**参数:**
- `bytecode`: 要部署的合约运行时字节码
- `salt`: 确定部署地址的唯一 bytes32 值

**返回值:**
- 新部署合约的地址

**Gas 消耗:** ~45,000（基础）+ 部署开销

**示例:**
```solidity
bytes memory bytecode = type(MyContract).creationCode;
bytes32 salt = keccak256(abi.encodePacked("unique-salt-123"));
address deployed = creator.deploy(bytecode, salt);
```

#### `predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address)`

在不实际部署的情况下计算合约将部署到的地址。

**参数:**
- `salt`: 与 `deploy()` 中使用的相同 salt 值
- `bytecodeHash`: 要部署合约的 `keccak256(bytecode)`

**返回值:**
- 合约将部署到的确定性地址

**Gas 消耗:** ~200（view 函数）

**示例:**
```solidity
bytes memory bytecode = type(MyContract).creationCode;
bytes32 bytecodeHash = keccak256(bytecode);
bytes32 salt = keccak256(abi.encodePacked("unique-salt-123"));
address predictedAddr = creator.predictAddress(salt, bytecodeHash);

// 稍后，在预测地址进行部署:
address actualAddr = creator.deploy(bytecode, salt);
assert(actualAddr == predictedAddr); // 总是为真
```

### 资产恢复函数

#### `withdrawERC20(address token) external onlyOwner`

恢复意外转入此合约的 ERC20 代币。

**参数:**
- `token`: ERC20 代币合约地址

**访问权限:** 仅所有者

**要求:**
- 合约必须有正余额的代币
- 代币转账必须成功（正确实现）

**Gas 消耗:** ~50,000

**原理:** ERC20 缺少接收器钩子，无法拒绝转账。此函数提供恢复机制。

**示例:**
```solidity
// 所有者恢复意外发送的 USDC
creator.withdrawERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
```

#### `withdrawERC721(address token, uint256 tokenId) external onlyOwner`

恢复转入合约的 ERC721 NFT。

**参数:**
- `token`: ERC721 代币合约地址
- `tokenId`: 要提取的代币 ID

**访问权限:** 仅所有者

**要求:**
- 合约必须拥有指定的代币
- 代币转账必须成功

**Gas 消耗:** ~60,000

**原理:** 标准的 ERC721 通过 `onERC721Received` 拒绝转账，但不兼容的实现可能会绕过此检查。此函数处理边界情况。

**示例:**
```solidity
// 所有者恢复意外发送的 NFT
creator.withdrawERC721(0x1234567890123456789012345678901234567890, 42);
```

### 拒绝函数

#### `onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4)`

实现 ERC721 接收器钩子以拒绝标准 ERC721 转账。

**行为:** 使用消息 "CCDAOCreator2: ERC721 tokens not accepted" 进行恢复

**自动:** 当标准 ERC721 合约尝试向此地址转账时自动调用。

#### `fallback() external`

捕获所有 ETH 转账并拒绝。

**行为:** 使用消息 "CCDAOCreator2: ETH not accepted" 进行恢复

**自动:** 当此合约接收 ETH 且没有匹配的函数选择器时自动调用。

## CREATE2 如何工作

CREATE2 使用以下方式确定性地计算部署地址:

```
address = keccak256(0xff ++ deployerAddress ++ salt ++ keccak256(bytecode))
```

其中:
- `0xff`: CREATE2 操作码前缀
- `deployerAddress`: 此合约的地址
- `salt`: 用户提供的唯一标识符
- `keccak256(bytecode)`: 合约字节码的哈希

### 影响

1. **地址是可预测的**: 部署前知道地址
2. **地址对每个字节码是唯一的**: 同一 salt 的不同字节码在不同地址
3. **Salt 碰撞安全**: 使用相同 salt 重新部署会失败（地址已有代码）
4. **跨链一致性**: 同一 salt + 字节码 = 所有 EVM 链上相同地址

## 设计决策

### 为什么拒绝 ETH?
通过 fallback 的 ETH 转账无法通过常规机制恢复。拒绝是最安全的做法。

### 为什么拒绝标准 ERC721?
标准 ERC721 实现接收器钩子检查。在此处拒绝可防止意外锁定。

### 为什么接受 ERC20 + 提供恢复?
ERC20 缺少接收器钩子—无法拒绝。提供所有者控制的提现是唯一实际的解决方案。

### 为什么提供 ERC721 恢复?
现实中的 ERC721 实现有时会跳过接收器钩子检查。此函数可以优雅地处理不兼容的合约。

## 资产处理矩阵

| 资产类型 | 传入转账 | 恢复函数 |
|----------|---------|---------|
| ETH | ❌ 被拒绝 (fallback revert) | N/A |
| ERC20 | ✅ 被接受 (无钩子阻止) | `withdrawERC20()` |
| ERC721 (标准) | ❌ 被拒绝 (onERC721Received revert) | N/A |
| ERC721 (不兼容) | ✅ 被接受 (无钩子检查) | `withdrawERC721()` |

## 测试

合约包含全面的测试覆盖:

```bash
# 运行所有测试
forge test

# 带详细输出运行
forge test -v

# 运行特定测试
forge test --match test_DeploySimpleContract
```

### 测试覆盖

- ✅ **部署测试**: 合约部署、salt 区分、地址预测准确性
- ✅ **资产拒绝测试**: ETH 拒绝、标准 ERC721 拒绝
- ✅ **资产恢复测试**: ERC20 恢复、不完整 ERC721 恢复
- ✅ **总计**: 8 个全面测试，全部通过

## 使用场景

1. **工厂合约**: 在可预测的地址部署合约实例
2. **跨链部署**: 在多个 EVM 链上的相同地址部署合约
3. **DAO 基础设施**: 在预定地址创建 DAO 金库/合约
4. **确定性初始化**: 为链下系统预计算合约地址
5. **虚荣地址**: 迭代 salt 以找到匹配特定模式的地址
6. **多签钱包**: 在确定性地址创建账户以增强安全性
7. **治理合约**: 在已知、不可变地址部署治理合约

## 安全考虑

### 此合约防护的内容
- ✅ 意外 ETH 转账（通过 fallback 拒绝）
- ✅ 标准 ERC721 转账（通过接收器钩子拒绝）
- ✅ 意外 ERC20 转账（通过所有者提现恢复）
- ✅ 不完整的 ERC721 实现（通过所有者提现恢复）

### 最佳实践
1. **Salt 管理**: 使用唯一、高熵的 salt 防止碰撞
2. **字节码验证**: 在部署前验证字节码
3. **所有者安全**: 使用多签或时间锁保护所有者密钥
4. **地址预测**: 始终验证 `predictAddress()` 与实际部署相匹配
5. **测试**: 在主网部署前在测试网上测试

## 配置

合约针对生产部署进行了优化，Foundry 设置如下:
```toml
optimizer_runs = 10000
```

这在部署成本和执行效率之间取得平衡。

## 部署

部署合约:
```bash
forge script script/CCDAOCreator2.s.sol --rpc-url $RPC_URL --broadcast
```

## 状态变量

### `address public owner`

此合约的所有者，被授权调用恢复函数。

## 修饰符

### `onlyOwner()`

将函数访问限制为合约所有者。

## 已部署信息

* ETH: 0x7cdcb326766541a82b2ec8c870747c780575eaee
* POLYGON: 0x358f2714b5b18938Fc146dD03D4fcC92666ecDC3
* ARB: 0xB416FdED89132B6c42BE4A32d5dF87Cc7DDD08d0
* BSC: 0xD13A52A139D74cbBAe4077CdfCa6F9edBa32B6dc
* BASE: 0x135a4Fa91E982080001633c8F68c6b1C66d22ca9

## 许可证

MIT
