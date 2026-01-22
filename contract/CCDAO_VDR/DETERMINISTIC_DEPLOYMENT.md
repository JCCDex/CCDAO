# 确定性部署（CREATE2）架构

## 概述

本文档说明 VDR（可验证数据注册中心）系统如何通过 CREATE2 实现完全确定性的合约部署，确保每次部署生成相同的合约地址。

## 部署架构

### 4 步部署流程

1. **步骤 1：部署 CREATE2 工厂合约（普通部署）**
   - 合约：`CCDAOCreator2`
   - 部署方式：标准 `deploy()`
   - 用途：作为后续 CREATE2 部署的工厂合约
   - 地址：固定（nonce 确定性）

2. **步骤 2：部署 VDR 实现合约（CREATE2 部署）**
   - 合约：`VDR.sol`
   - 部署方式：CREATE2，使用固定 salt `keccak256('VDR')`
   - 目的：VDR 核心逻辑实现
   - 地址：`0x1d9D9D83A0E26e24503C0c36e600947D10A3F184`（示例）
   - 确定性：✅ 固定 salt → 固定地址

3. **步骤 3：部署 VDRFactory 实现合约（CREATE2 部署）**
   - 合约：`VDRFactory.sol`
   - 部署方式：CREATE2，使用固定 salt `keccak256('VDRFactory')`
   - 目的：VDR 实例工厂（可升级合约的实现部分）
   - 地址：`0x40e4Be122896c51A52E4631d85914de7D816725D`（示例）
   - 确定性：✅ 固定 salt → 固定地址

4. **步骤 4：部署 VDRFactory 代理（CREATE2 部署）**
   - 合约：`ERC1967Proxy` + `VDRFactory` 初始化
   - 部署方式：CREATE2，使用固定 salt `keccak256('VDRFactoryProxy')`
   - 目的：可升级代理，指向 VDRFactory 实现
   - 地址：`0xc558AbEAaaaF0bdCba3167A1ef60e8d208F7c9Bb`（示例）
   - 初始化参数：
     - Admin: 部署者账户
     - VDRFactory 实现地址
     - CCDAOCreator2 地址
   - 确定性：✅ 固定 salt + 初始化数据 → 固定地址

## 关键实现细节

### CREATE2 部署

```javascript
// CREATE2 盐值定义
const vdrSalt = ethers.keccak256(ethers.toUtf8Bytes('VDR'));
const vdrFactorySalt = ethers.keccak256(ethers.toUtf8Bytes('VDRFactory'));
const proxyProxySalt = ethers.keccak256(ethers.toUtf8Bytes('VDRFactoryProxy'));

// CREATE2 部署函数
async function deployWithCreate2(name, bytecode, salt, create2Address, signer) {
  const create2Contract = new ethers.Contract(
    create2Address,
    ['function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address)'],
    signer
  );
  
  const tx = await create2Contract.deploy(bytecode, salt, { nonce: currentNonce });
  currentNonce++;
  await tx.wait();
  
  return predictedAddress;
}
```

### 代理初始化

```javascript
// 构建代理 bytecode（包含初始化数据）
const proxyBytecode = ethers.solidityPacked(
  ['bytes', 'bytes'],
  [
    erc1967ProxyJson.bytecode.object,
    ethers.AbiCoder.defaultAbiCoder().encode(
      ['address', 'bytes'],
      [vdrFactoryImplementationAddress, initCall]
    )
  ]
);

// 其中 initCall 是初始化函数编码
const iface = new ethers.Interface(vdrFactoryJson.abi);
const initCall = iface.encodeFunctionData('initialize', [
  deployer.address,
  vdrImplementationAddress,
  ccdaoCreate2Address
]);
```

## Nonce 管理

### 问题
初期部署时，ethers v6 在连续发送多笔交易时，nonce 管理出现问题，导致"nonce has already been used"错误。

### 解决方案
实现全局 nonce 计数器，手动管理每笔交易的 nonce：

```javascript
let currentNonce = null;

async function initNonce() {
  currentNonce = await provider.getTransactionCount(deployer.address);
}

async function deployContract(...) {
  // 显式指定 nonce
  const contract = await factory.deploy(...args, { nonce: currentNonce });
  currentNonce++; // 手动递增
  await contract.waitForDeployment();
}
```

## 确定性验证

### 验证方式

1. **第一次部署**：记录所有 4 个合约地址
2. **重启 Anvil**：完全清空链状态
3. **第二次部署**：运行相同的部署脚本
4. **比对结果**：验证所有地址完全相同

### 验证结果 ✅

```
第一次部署 → 第二次部署
CCDAOCreator2:    0x5FbDB2... → 0x5FbDB2... ✅ 相同
VDR:              0x1d9D9D... → 0x1d9D9D... ✅ 相同
VDRFactory:       0x40e4Be... → 0x40e4Be... ✅ 相同
VDRFactoryProxy:  0xc558Ab... → 0xc558Ab... ✅ 相同
```

## 部署脚本

### 执行部署

```bash
npm run deploy
```

### 脚本位置
- [scripts/deploy.js](../tools/scripts/deploy.js)

### 部署地址输出
- 地址保存至：[artifacts/deployment.json](../tools/artifacts/deployment.json)

## 升级流程

由于使用了可升级代理（ERC1967Proxy）模式：

1. VDR 实现升级：部署新 VDR，更新代理指向（需要 CCDAOCreator2 支持）
2. VDRFactory 升级：部署新 VDRFactory，调用代理的 `upgradeTo()` 方法

每次升级的代理地址保持不变，只需更新实现合约地址。

## 生产环境部署

在生产环境（如以太坊主网）部署时：

1. 确保使用相同的部署账户（nonce 序列相同）
2. 确保 gas 价格足够（某些网络对 gas 价格敏感）
3. 使用 CREATE2 验证部署的确定性：
   ```bash
   # 验证码：
   CCDAOCreator2 部署信息
   VDR salt: keccak256('VDR')
   VDRFactory salt: keccak256('VDRFactory')
   VDRFactoryProxy salt: keccak256('VDRFactoryProxy')
   ```

## 参考资源

- [CREATE2 规范](https://eips.ethereum.org/EIPS/eip-1014)
- [ERC1967 可升级代理](https://eips.ethereum.org/EIPS/eip-1967)
- [ethers.js 文档](https://docs.ethers.org/v6/)

## 测试验证

### 运行集成测试

```bash
npm run test:integration
```

### 运行完整管道

```bash
bash run-all.sh
```

预期结果：
- ✅ 编译成功
- ✅ 部署成功（4 个合约）
- ✅ 集成测试通过（4/7 个测试）

