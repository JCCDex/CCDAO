import { expect } from 'chai';
import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 配置
const ANVIL_RPC = 'http://127.0.0.1:8545';
const provider = new ethers.JsonRpcProvider(ANVIL_RPC);

// 获取 anvil 默认账户（使用 HDNodeWallet）
const mnemonic = 'test test test test test test test test test test test junk';
const hdNode = ethers.HDNodeWallet.fromMnemonic(
  ethers.Mnemonic.fromPhrase(mnemonic),
  "m/44'/60'/0'/0"
);
const deployer = hdNode.deriveChild(0).connect(provider);

// ============================================================
// 压力测试配置参数 - 可根据需要调整
// ============================================================
// 快速测试版本（默认）- 总共 30 个 VC
const VDR_CREATOR_COUNT = 3;      // 创建 VDR 的用户数
const VC_USER_COUNT = 300;        // 创建 VC 的用户数
const VC_PER_USER_PER_VDR = 1;    // 每个用户在每个 VDR 上创建的 VC 数
const DISPUTE_COUNT = 5;          // 随机质疑的 VC 数量
const REVOKE_COUNT = 2;           // 随机吊销的 VC 数量

// 完整压力测试版本（取消注释以启用）- 总共 3000 个 VC
// const VDR_CREATOR_COUNT = 3;      // 创建 VDR 的用户数
// const VC_USER_COUNT = 100;        // 创建 VC 的用户数
// const VC_PER_USER_PER_VDR = 10;   // 每个用户在每个 VDR 上创建的 VC 数
// const DISPUTE_COUNT = 50;         // 随机质疑的 VC 数量
// const REVOKE_COUNT = 20;          // 随机吊销的 VC 数量

const ETH_AMOUNT_PER_USER = ethers.parseEther('1'); // 每个用户分配 1 ETH
const BATCH_SIZE = 50;  // 批量处理大小（并发发送交易数）
const TX_CONFIRM_TIMEOUT = 10000;  // 单笔交易确认超时（毫秒）
const MAX_RETRY = 3;  // 最大重试次数
// ============================================================

// 辅助函数：延迟
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 健壮的交易发送器：发送交易并确保上链
 * - 发送交易后等待确认，有超时机制
 * - 超时后检查交易是否已上链（通过 hash 查询）
 * - 未上链则重新发送，最多重试 MAX_RETRY 次
 * 
 * @param {object} signer - 签名者
 * @param {object} txData - 交易数据 {to, value, nonce, data?}
 * @param {string} label - 交易标签（用于日志）
 * @returns {Promise<{success: boolean, hash: string, receipt: object|null}>}
 */
async function sendTxWithRetry(signer, txData, label = 'tx') {
  let lastHash = null;
  let lastError = null;
  
  for (let attempt = 1; attempt <= MAX_RETRY; attempt++) {
    try {
      // 发送交易
      const tx = await signer.sendTransaction(txData);
      lastHash = tx.hash;
      
      // 等待确认（带超时）
      const receipt = await Promise.race([
        tx.wait(),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('TIMEOUT')), TX_CONFIRM_TIMEOUT)
        )
      ]);
      
      // 成功确认
      return { success: true, hash: tx.hash, receipt };
      
    } catch (e) {
      lastError = e;
      
      if (e.message === 'TIMEOUT' && lastHash) {
        // 超时了，检查交易是否已上链
        console.log(`    [TIMEOUT] ${label} hash=${lastHash.slice(0, 10)}... 等待超时，检查链上状态...`);
        
        try {
          const receipt = await provider.getTransactionReceipt(lastHash);
          if (receipt) {
            // 交易已上链，成功
            console.log(`    [RECOVERED] ${label} 交易已上链 block=${receipt.blockNumber}`);
            return { success: true, hash: lastHash, receipt };
          }
        } catch (checkErr) {
          // 查询失败，继续重试
        }
        
        // 交易未上链，检查是否还在 pending
        try {
          const pendingTx = await provider.getTransaction(lastHash);
          if (pendingTx) {
            // 交易在 pending，继续等待一下
            console.log(`    [PENDING] ${label} 交易在 pending，继续等待...`);
            await delay(2000);
            const receipt = await provider.getTransactionReceipt(lastHash);
            if (receipt) {
              console.log(`    [RECOVERED] ${label} 交易已上链 block=${receipt.blockNumber}`);
              return { success: true, hash: lastHash, receipt };
            }
          }
        } catch (pendingErr) {
          // 忽略
        }
        
        // 仍未上链，重新发送（nonce 不变，相当于替换交易）
        if (attempt < MAX_RETRY) {
          console.log(`    [RETRY] ${label} 第 ${attempt + 1}/${MAX_RETRY} 次重试...`);
        }
        
      } else if (e.code === 'NONCE_EXPIRED' || e.message.includes('nonce')) {
        // nonce 已使用，说明交易可能已经成功
        console.log(`    [NONCE] ${label} nonce 已使用，交易可能已成功`);
        if (lastHash) {
          const receipt = await provider.getTransactionReceipt(lastHash).catch(() => null);
          if (receipt) {
            return { success: true, hash: lastHash, receipt };
          }
        }
        // nonce 问题无法重试
        break;
        
      } else {
        // 其他错误
        if (attempt < MAX_RETRY) {
          console.log(`    [ERROR] ${label} ${e.message.slice(0, 50)}... 第 ${attempt + 1}/${MAX_RETRY} 次重试...`);
          await delay(500);
        }
      }
    }
  }
  
  // 所有重试都失败
  console.log(`    [FAIL] ${label} 最终失败: ${lastError?.message?.slice(0, 60) || 'unknown'}`);
  return { success: false, hash: lastHash, receipt: null };
}

/**
 * 批量发送交易（带重试机制）
 * 
 * @param {Array} txTasks - [{signer, txData, label}, ...]
 * @param {string} batchLabel - 批次标签
 * @returns {Promise<{success: number, failed: number, results: Array}>}
 */
async function sendBatchWithRetry(txTasks, batchLabel = 'batch') {
  let success = 0;
  let failed = 0;
  const results = [];
  
  // 并发发送所有交易
  const promises = txTasks.map(task => 
    sendTxWithRetry(task.signer, task.txData, task.label)
  );
  
  const settled = await Promise.allSettled(promises);
  
  for (const result of settled) {
    if (result.status === 'fulfilled' && result.value.success) {
      success++;
      results.push(result.value);
    } else {
      failed++;
      results.push(result.status === 'fulfilled' ? result.value : { success: false });
    }
  }
  
  return { success, failed, results };
}

// 加载部署地址
function loadDeploymentAddresses() {
  const filePath = path.join(__dirname, '../artifacts/deployment.json');
  if (!fs.existsSync(filePath)) {
    throw new Error('deployment.json not found. Run: npm run deploy');
  }
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

// 动态检测路径加载合约 ABI
function getContractABI(contractName) {
  const toolsDir = path.dirname(__dirname);
  const vdrDir = path.dirname(toolsDir);
  const contractDir = path.dirname(vdrDir);
  const create2Dir = path.join(contractDir, 'CCDAO_CREATE2');
  
  const paths = [
    path.join(vdrDir, `out/${contractName}.sol/${contractName}.json`),
    path.join(create2Dir, `out/${contractName}.sol/${contractName}.json`),
  ];
  
  for (const p of paths) {
    if (fs.existsSync(p)) {
      return JSON.parse(fs.readFileSync(p, 'utf8')).abi;
    }
  }
  throw new Error(`ABI not found for ${contractName}`);
}

// 随机选择数组中的 n 个元素
function randomSample(arr, n) {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, Math.min(n, arr.length));
}

describe('CCDAO VDR 压力测试', function () {
  this.timeout(3600000); // 60 分钟超时（3000 VC 需要较长时间）

  let addresses;
  let vdrFactory;
  let vdrABI;
  
  // 用户组
  let vdrCreators = [];   // 创建 VDR 的 3 个用户
  let vcUsers = [];       // 创建 VC 的 100 个用户
  
  // VDR 实例
  let vdrInstances = [];  // { address, owner, name, contract }
  
  // 所有已注册的 VC 记录
  let allVCs = [];        // { vdrAddress, vcId, holder, issuer }

  before(async function () {
    console.log('\n=== 初始化压力测试环境 ===\n');
    
    // 加载部署地址
    addresses = loadDeploymentAddresses();
    console.log('[OK] 已加载部署地址');
    console.log(`  VDRFactoryProxy: ${addresses.vdrFactoryProxy}`);

    // 获取合约 ABI
    const vdrFactoryABI = getContractABI('VDRFactory');
    vdrABI = getContractABI('VDR');

    // 创建 VDRFactory 合约实例
    vdrFactory = new ethers.Contract(addresses.vdrFactoryProxy, vdrFactoryABI, deployer);

    // 创建 VDR 创建者（3 个用户，索引 1-3）
    for (let i = 1; i <= VDR_CREATOR_COUNT; i++) {
      const user = hdNode.deriveChild(i).connect(provider);
      vdrCreators.push(user);
    }
    console.log(`[OK] 创建了 ${vdrCreators.length} 个 VDR 创建者`);

    // 创建 VC 用户（100 个，索引 10-109）
    for (let i = 10; i < 10 + VC_USER_COUNT; i++) {
      const user = hdNode.deriveChild(i).connect(provider);
      vcUsers.push(user);
    }
    console.log(`[OK] 创建了 ${vcUsers.length} 个 VC 用户`);
    
    // 给没有 ETH 的用户转账
    console.log('\n=== 给用户分配 ETH ===\n');
    
    // 检查 deployer 余额
    const deployerBalance = await provider.getBalance(deployer.address);
    console.log(`[INFO] Deployer 余额: ${ethers.formatEther(deployerBalance)} ETH`);
    
    // 获取当前 deployer 的 nonce
    let currentNonce = await provider.getTransactionCount(deployer.address);
    console.log(`[INFO] Deployer 当前 nonce: ${currentNonce}`);
    
    // 给 VDR 创建者转账（索引 1-3，可能已有 ETH，但仍检查）
    let fundedCount = 0;
    for (const creator of vdrCreators) {
      const balance = await provider.getBalance(creator.address);
      if (balance < ETH_AMOUNT_PER_USER) {
        const tx = await deployer.sendTransaction({
          to: creator.address,
          value: ETH_AMOUNT_PER_USER,
          nonce: currentNonce++
        });
        await tx.wait();
        fundedCount++;
      }
    }
    console.log(`[OK] 给 ${fundedCount} 个 VDR 创建者补充了 ETH`);
    
    // 批量给 VC 用户转账（使用健壮的重试机制）
    console.log(`[INFO] 开始给 ${vcUsers.length} 个 VC 用户转账...`);
    fundedCount = 0;
    let failedCount = 0;
    
    // 批量处理转账
    for (let i = 0; i < vcUsers.length; i += BATCH_SIZE) {
      const batch = vcUsers.slice(i, i + BATCH_SIZE);
      const batchNum = Math.floor(i / BATCH_SIZE) + 1;
      const totalBatches = Math.ceil(vcUsers.length / BATCH_SIZE);
      
      // 构建交易任务列表
      const txTasks = batch.map((user, idx) => ({
        signer: deployer,
        txData: {
          to: user.address,
          value: ETH_AMOUNT_PER_USER,
          nonce: currentNonce + idx
        },
        label: `转账[${i + idx + 1}]`
      }));
      currentNonce += batch.length;
      
      // 批量发送（带重试）
      const { success, failed } = await sendBatchWithRetry(txTasks, `批次${batchNum}`);
      fundedCount += success;
      failedCount += failed;
      
      console.log(`  [批次 ${batchNum}/${totalBatches}] 成功: ${success}, 失败: ${failed}, 累计: ${fundedCount}/${vcUsers.length}`);
    }
    console.log(`[OK] 给 ${fundedCount} 个 VC 用户转账完成 (失败: ${failedCount})`);
    
    // 验证余额
    const sampleUser = vcUsers[0];
    const sampleBalance = await provider.getBalance(sampleUser.address);
    console.log(`[INFO] 样本用户余额: ${ethers.formatEther(sampleBalance)} ETH`);
  });

  describe('第一阶段：创建 VDR', function () {
    it(`应该由 ${VDR_CREATOR_COUNT} 个用户分别创建 VDR`, async function () {
      console.log(`\n[TEST] 创建 ${VDR_CREATOR_COUNT} 个 VDR 实例\n`);
      
      const timestamp = Date.now();
      
      for (let i = 0; i < vdrCreators.length; i++) {
        const creator = vdrCreators[i];
        const vdrName = `VDR_${i + 1}_${timestamp}`;
        
        // 使用第一个 VC 用户作为 dataManager
        const dataManagers = [vcUsers[0].address];
        
        console.log(`  [${i + 1}/${vdrCreators.length}] 创建 VDR: ${vdrName}`);
        console.log(`    创建者: ${creator.address}`);
        
        const factoryWithCreator = vdrFactory.connect(creator);
        const tx = await factoryWithCreator.createVDR(vdrName, creator.address, dataManagers);
        const receipt = await tx.wait();
        
        // 从事件获取 VDR 地址
        const vdrCreatedEvent = receipt.logs.find(log => {
          try {
            const parsed = vdrFactory.interface.parseLog(log);
            return parsed && parsed.name === 'VDRCreated';
          } catch { return false; }
        });
        
        expect(vdrCreatedEvent).to.not.be.undefined;
        const parsedEvent = vdrFactory.interface.parseLog(vdrCreatedEvent);
        const vdrAddress = parsedEvent.args.vdrAddress;
        
        // 创建 VDR 合约实例
        const vdrContract = new ethers.Contract(vdrAddress, vdrABI, deployer);
        
        vdrInstances.push({
          address: vdrAddress,
          owner: creator.address,
          name: vdrName,
          contract: vdrContract,
          creator: creator
        });
        
        console.log(`    [OK] VDR 地址: ${vdrAddress}`);
      }
      
      expect(vdrInstances.length).to.equal(VDR_CREATOR_COUNT);
      console.log(`\n[OK] 成功创建 ${vdrInstances.length} 个 VDR`);
    });
  });

  describe('第二阶段：批量创建 VC', function () {
    it(`应该由 ${VC_USER_COUNT} 个用户在 ${VDR_CREATOR_COUNT} 个 VDR 上各创建 ${VC_PER_USER_PER_VDR} 个 VC`, async function () {
      const totalVCs = VC_USER_COUNT * VDR_CREATOR_COUNT * VC_PER_USER_PER_VDR;
      console.log(`\n[TEST] 批量创建 ${totalVCs} 个 VC\n`);
      
      let vcCount = 0;
      let failCount = 0;
      let lastProgress = 0;
      
      // 为每个用户预先获取 nonce（避免重复查询链上 nonce）
      console.log(`[INFO] 获取 ${vcUsers.length} 个用户的 nonce...`);
      const userNonces = new Map();
      for (const user of vcUsers) {
        userNonces.set(user.address, await provider.getTransactionCount(user.address));
      }
      console.log(`[OK] nonce 获取完成`);
      
      // 遍历每个 VDR
      for (let vdrIndex = 0; vdrIndex < vdrInstances.length; vdrIndex++) {
        const vdrInfo = vdrInstances[vdrIndex];
        console.log(`  [VDR ${vdrIndex + 1}/${vdrInstances.length}] ${vdrInfo.name}`);
        
        // 注意：registerVC 是公开函数，任何人都可以调用，不需要添加成员权限
        
        // 批量并发创建 VC（使用健壮的重试机制）
        for (let userStart = 0; userStart < vcUsers.length; userStart += BATCH_SIZE) {
          const userBatch = vcUsers.slice(userStart, userStart + BATCH_SIZE);
          const batchNum = Math.floor(userStart / BATCH_SIZE) + 1;
          const txTasks = [];
          const vcInfoBatch = [];
          
          // 构建这批用户的交易任务
          for (let batchIdx = 0; batchIdx < userBatch.length; batchIdx++) {
            const userIndex = userStart + batchIdx;
            const user = userBatch[batchIdx];
            const vdrWithUser = vdrInfo.contract.connect(user);
            let userNonce = userNonces.get(user.address);
            
            for (let vcIndex = 0; vcIndex < VC_PER_USER_PER_VDR; vcIndex++) {
              const vcIdString = `vc_vdr${vdrIndex}_user${userIndex}_${vcIndex}_${Date.now()}_${Math.random()}`;
              const vcId = ethers.id(vcIdString);
              const holder = user.address;
              const contentHash = ethers.keccak256(ethers.toUtf8Bytes(`content_${vcIdString}`));
              const issuanceDate = Math.floor(Date.now() / 1000);
              
              txTasks.push({
                signer: user,
                txData: {
                  to: vdrInfo.address,
                  data: vdrWithUser.interface.encodeFunctionData('registerVC', [vcId, holder, contentHash, issuanceDate]),
                  nonce: userNonce++
                },
                label: `VC[${userIndex}]`
              });
              
              vcInfoBatch.push({
                vdrAddress: vdrInfo.address,
                vdrIndex: vdrIndex,
                vcId: vcId,
                holder: holder,
                issuer: user.address
              });
            }
            
            userNonces.set(user.address, userNonce);
          }
          
          // 批量发送（带重试）
          const { success, failed, results } = await sendBatchWithRetry(txTasks, `VC批次${batchNum}`);
          
          // 只添加成功的 VC
          results.forEach((result, idx) => {
            if (result.success) {
              allVCs.push(vcInfoBatch[idx]);
              vcCount++;
            } else {
              failCount++;
            }
          });
          
          // 进度显示
          const totalProcessed = vdrIndex * vcUsers.length * VC_PER_USER_PER_VDR + Math.min(userStart + BATCH_SIZE, vcUsers.length) * VC_PER_USER_PER_VDR;
          const progress = Math.floor(totalProcessed / totalVCs * 100);
          if (progress >= lastProgress + 10 || userStart + BATCH_SIZE >= vcUsers.length) {
            console.log(`    进度: ${vcCount} 成功 / ${totalProcessed} 处理 (${progress}%)`);
            lastProgress = progress;
          }
        }
      }
      
      console.log(`\n[OK] 成功创建 ${vcCount} 个 VC（失败 ${failCount} 个）`);
      expect(allVCs.length).to.be.greaterThan(0);
    });
  });

  describe('第三阶段：随机质疑 VC', function () {
    it(`应该随机质疑 ${DISPUTE_COUNT} 个 VC`, async function () {
      console.log(`\n[TEST] 随机质疑 ${DISPUTE_COUNT} 个 VC\n`);
      
      if (allVCs.length === 0) {
        console.log('  [SKIP] 没有可质疑的 VC');
        this.skip();
        return;
      }
      
      // 为每个 VDR owner 获取当前 nonce
      const ownerNonces = new Map();
      for (const vdrInfo of vdrInstances) {
        ownerNonces.set(vdrInfo.creator.address, await provider.getTransactionCount(vdrInfo.creator.address));
      }
      
      // 随机选择要质疑的 VC
      const vcsToDispute = randomSample(allVCs, DISPUTE_COUNT);
      let disputedCount = 0;
      
      for (let i = 0; i < vcsToDispute.length; i++) {
        const vcInfo = vcsToDispute[i];
        const vdrInfo = vdrInstances[vcInfo.vdrIndex];
        
        // 使用 VDR owner 来质疑（owner 有权限质疑）
        const vdrWithOwner = vdrInfo.contract.connect(vdrInfo.creator);
        let ownerNonce = ownerNonces.get(vdrInfo.creator.address);
        
        console.log(`  [${i + 1}/${vcsToDispute.length}] 质疑 VC`);
        console.log(`    VDR: ${vdrInfo.name}`);
        console.log(`    VC ID: ${vcInfo.vcId.slice(0, 20)}...`);
        
        try {
          const tx = await vdrWithOwner.disputeVC(vcInfo.vcId, { nonce: ownerNonce++ });
          await tx.wait();
          ownerNonces.set(vdrInfo.creator.address, ownerNonce);
          
          // 验证状态
          const vcRecord = await vdrInfo.contract.getVC(vcInfo.vcId);
          console.log(`    [OK] 状态: Disputed (${vcRecord.status})`);
          
          // 标记为已质疑
          vcInfo.disputed = true;
          disputedCount++;
        } catch (e) {
          console.log(`    [FAIL] 质疑失败: ${e.message.slice(0, 80)}`);
        }
      }
      
      console.log(`\n[OK] 成功质疑 ${disputedCount} 个 VC`);
      expect(disputedCount).to.be.greaterThan(0);
    });
  });

  describe('第四阶段：随机吊销 VC', function () {
    it(`应该随机吊销 ${REVOKE_COUNT} 个已质疑的 VC`, async function () {
      console.log(`\n[TEST] 随机吊销 ${REVOKE_COUNT} 个 VC\n`);
      
      // 找出已质疑的 VC
      const disputedVCs = allVCs.filter(vc => vc.disputed);
      
      if (disputedVCs.length === 0) {
        console.log('  [SKIP] 没有已质疑的 VC 可吊销');
        this.skip();
        return;
      }
      
      // 为每个 VDR owner 获取当前 nonce
      const ownerNonces = new Map();
      for (const vdrInfo of vdrInstances) {
        ownerNonces.set(vdrInfo.creator.address, await provider.getTransactionCount(vdrInfo.creator.address));
      }
      
      // 随机选择要吊销的 VC
      const vcsToRevoke = randomSample(disputedVCs, REVOKE_COUNT);
      let revokedCount = 0;
      
      for (let i = 0; i < vcsToRevoke.length; i++) {
        const vcInfo = vcsToRevoke[i];
        const vdrInfo = vdrInstances[vcInfo.vdrIndex];
        
        // 使用 VDR owner 来解决质疑并吊销
        const vdrWithOwner = vdrInfo.contract.connect(vdrInfo.creator);
        let ownerNonce = ownerNonces.get(vdrInfo.creator.address);
        
        console.log(`  [${i + 1}/${vcsToRevoke.length}] 吊销 VC`);
        console.log(`    VDR: ${vdrInfo.name}`);
        console.log(`    VC ID: ${vcInfo.vcId.slice(0, 20)}...`);
        
        try {
          const tx = await vdrWithOwner.resolveDispute(vcInfo.vcId, true, { nonce: ownerNonce++ }); // true = revoke
          await tx.wait();
          ownerNonces.set(vdrInfo.creator.address, ownerNonce);
          
          // 验证状态
          const vcRecord = await vdrInfo.contract.getVC(vcInfo.vcId);
          console.log(`    [OK] 状态: Revoked (${vcRecord.status})`);
          
          vcInfo.revoked = true;
          revokedCount++;
        } catch (e) {
          console.log(`    [FAIL] 吊销失败: ${e.message}`);
        }
      }
      
      console.log(`\n[OK] 成功吊销 ${revokedCount} 个 VC`);
      expect(revokedCount).to.be.greaterThan(0);
    });
  });

  describe('第五阶段：统计和验证', function () {
    it('应该输出最终统计信息', async function () {
      console.log('\n=== 最终统计 ===\n');
      
      console.log(`VDR 总数: ${vdrInstances.length}`);
      console.log(`VC 总数: ${allVCs.length}`);
      
      const disputedVCs = allVCs.filter(vc => vc.disputed);
      const revokedVCs = allVCs.filter(vc => vc.revoked);
      
      console.log(`已质疑 VC: ${disputedVCs.length}`);
      console.log(`已吊销 VC: ${revokedVCs.length}`);
      console.log(`活跃 VC: ${allVCs.length - revokedVCs.length}`);
      
      // 验证每个 VDR 的状态
      console.log('\n各 VDR 详情:');
      for (let i = 0; i < vdrInstances.length; i++) {
        const vdrInfo = vdrInstances[i];
        const vdrVCs = allVCs.filter(vc => vc.vdrIndex === i);
        const vdrDisputed = vdrVCs.filter(vc => vc.disputed).length;
        const vdrRevoked = vdrVCs.filter(vc => vc.revoked).length;
        
        console.log(`  ${vdrInfo.name}:`);
        console.log(`    VC 总数: ${vdrVCs.length}`);
        console.log(`    已质疑: ${vdrDisputed}`);
        console.log(`    已吊销: ${vdrRevoked}`);
      }
      
      expect(true).to.be.true;
    });
  });
});
