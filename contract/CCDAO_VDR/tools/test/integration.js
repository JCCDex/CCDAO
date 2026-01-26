#!/usr/bin/env node
/**
 * CCDAO VDR 集成测试 - 压力测试脚本
 * 
 * 功能：
 * 1. 创建多个 VDR 实例
 * 2. 批量注册大量 VC
 * 3. 随机质疑和吊销 VC
 * 4. 验证最终状态
 * 
 * 用法：node integration.js [--users=N] [--vdrs=N]
 */

import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================
// 配置参数
// ============================================================
const CONFIG = {
  // RPC 配置
  rpc: 'http://127.0.0.1:8545',
  mnemonic: 'test test test test test test test test test test test junk',
  
  // 测试规模（可通过命令行参数覆盖）
  vdrCount: 3,           // VDR 数量
  vcUserCount: 1000,      // VC 用户数量
  vcPerUser: 1,          // 每用户每 VDR 的 VC 数
  disputeCount: 50,       // 质疑数量
  revokeCount: 20,        // 吊销数量
  
  // 执行参数
  batchSize: 50,         // 批量并发数
  ethPerUser: '1',       // 每用户 ETH 数量
  
  // 重试配置
  maxRetry: 3,           // 最大重试次数
  retryDelay: 1000,      // 重试间隔 (ms)
  txTimeout: 15000,      // 交易超时 (ms)
};

// ============================================================
// 工具函数
// ============================================================

function log(msg) {
  console.log(`[${new Date().toISOString().slice(11, 19)}] ${msg}`);
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function randomSample(arr, n) {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, Math.min(n, arr.length));
}

function loadDeploymentAddresses() {
  const filePath = path.join(__dirname, '../artifacts/deployment.json');
  if (!fs.existsSync(filePath)) {
    throw new Error('deployment.json not found. Run: npm run deploy');
  }
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

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

// ============================================================
// 交易发送器（带重试和复查）
// ============================================================

class TxSender {
  constructor(provider, config) {
    this.provider = provider;
    this.config = config;
    this.pendingTxs = new Map(); // hash -> {txData, signer, label, attempts}
  }

  /**
   * 发送单笔交易，失败时自动重试
   */
  async send(signer, txData, label = 'tx') {
    let lastHash = null;
    let lastError = null;

    for (let attempt = 1; attempt <= this.config.maxRetry; attempt++) {
      try {
        const tx = await signer.sendTransaction(txData);
        lastHash = tx.hash;

        // 等待确认（带超时）
        const receipt = await Promise.race([
          tx.wait(),
          delay(this.config.txTimeout).then(() => { throw new Error('TIMEOUT'); })
        ]);

        return { success: true, hash: tx.hash, receipt };

      } catch (e) {
        lastError = e;

        if (e.message === 'TIMEOUT' && lastHash) {
          // 超时，检查链上状态
          const receipt = await this.checkTxOnChain(lastHash);
          if (receipt) {
            return { success: true, hash: lastHash, receipt };
          }

          // 未上链，记录待复查
          if (attempt === this.config.maxRetry) {
            this.pendingTxs.set(lastHash, { txData, signer, label, attempts: attempt });
          }

        } else if (e.code === 'NONCE_EXPIRED' || (e.message && e.message.includes('nonce'))) {
          // nonce 已使用，可能交易已成功
          if (lastHash) {
            const receipt = await this.checkTxOnChain(lastHash);
            if (receipt) return { success: true, hash: lastHash, receipt };
          }
          break;

        } else if (attempt < this.config.maxRetry) {
          await delay(this.config.retryDelay);
        }
      }
    }

    return { success: false, hash: lastHash, error: lastError?.message };
  }

  /**
   * 检查交易是否已上链
   */
  async checkTxOnChain(hash) {
    try {
      const receipt = await this.provider.getTransactionReceipt(hash);
      if (receipt && receipt.status === 1) return receipt;
    } catch {}
    return null;
  }

  /**
   * 批量发送交易
   * @param {Array} tasks - [{signer, txData, label}, ...]
   * @returns {{success: number, failed: number, results: Array}}
   */
  async sendBatch(tasks) {
    const promises = tasks.map(t => this.send(t.signer, t.txData, t.label));
    const results = await Promise.allSettled(promises);

    let success = 0, failed = 0;
    const outputs = [];

    for (const r of results) {
      if (r.status === 'fulfilled' && r.value.success) {
        success++;
        outputs.push(r.value);
      } else {
        failed++;
        outputs.push(r.status === 'fulfilled' ? r.value : { success: false });
      }
    }

    return { success, failed, results: outputs };
  }

  /**
   * 复查所有待确认交易
   */
  async recheckPending() {
    if (this.pendingTxs.size === 0) return { recovered: 0, stillPending: 0 };

    log(`复查 ${this.pendingTxs.size} 笔待确认交易...`);
    let recovered = 0, stillPending = 0;

    for (const [hash, info] of this.pendingTxs.entries()) {
      const receipt = await this.checkTxOnChain(hash);
      if (receipt) {
        recovered++;
        this.pendingTxs.delete(hash);
      } else {
        stillPending++;
      }
    }

    log(`复查完成: 已确认 ${recovered}, 仍待确认 ${stillPending}`);
    return { recovered, stillPending };
  }
}

// ============================================================
// 主程序
// ============================================================

class VDRIntegrationTest {
  constructor(config) {
    this.config = config;
    this.provider = new ethers.JsonRpcProvider(config.rpc);
    
    const hdNode = ethers.HDNodeWallet.fromMnemonic(
      ethers.Mnemonic.fromPhrase(config.mnemonic),
      "m/44'/60'/0'/0"
    );
    this.hdNode = hdNode;
    this.deployer = hdNode.deriveChild(0).connect(this.provider);
    this.txSender = new TxSender(this.provider, config);

    // 状态
    this.vdrCreators = [];
    this.vcUsers = [];
    this.vdrInstances = [];
    this.allVCs = [];
  }

  async run() {
    const startTime = Date.now();
    log('========================================');
    log('CCDAO VDR 集成测试开始');
    log('========================================');
    log(`配置: ${this.config.vdrCount} VDR, ${this.config.vcUserCount} 用户, ${this.config.vcPerUser} VC/用户`);

    try {
      await this.init();
      await this.fundUsers();
      await this.createVDRs();
      await this.registerVCs();
      await this.disputeVCs();
      await this.revokeVCs();
      await this.recheckAndRetry();
      this.printSummary();

      const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
      log('========================================');
      log(`测试完成，耗时 ${elapsed} 秒`);
      log('========================================');

    } catch (e) {
      log(`❌ 测试失败: ${e.message}`);
      console.error(e);
      process.exit(1);
    }
  }

  async init() {
    log('--- 初始化 ---');

    // 加载部署地址
    this.addresses = loadDeploymentAddresses();
    log(`VDRFactory: ${this.addresses.vdrFactoryProxy}`);

    // 加载 ABI
    const vdrFactoryABI = getContractABI('VDRFactory');
    this.vdrABI = getContractABI('VDR');
    this.vdrFactory = new ethers.Contract(this.addresses.vdrFactoryProxy, vdrFactoryABI, this.deployer);

    // 创建用户钱包
    for (let i = 1; i <= this.config.vdrCount; i++) {
      this.vdrCreators.push(this.hdNode.deriveChild(i).connect(this.provider));
    }
    for (let i = 10; i < 10 + this.config.vcUserCount; i++) {
      this.vcUsers.push(this.hdNode.deriveChild(i).connect(this.provider));
    }

    log(`创建了 ${this.vdrCreators.length} 个 VDR 创建者, ${this.vcUsers.length} 个 VC 用户`);
  }

  async fundUsers() {
    log('--- 分配 ETH ---');

    const ethAmount = ethers.parseEther(this.config.ethPerUser);
    let nonce = await this.provider.getTransactionCount(this.deployer.address);

    // 给 VDR 创建者转账
    for (const creator of this.vdrCreators) {
      const balance = await this.provider.getBalance(creator.address);
      if (balance < ethAmount) {
        const tx = await this.deployer.sendTransaction({
          to: creator.address,
          value: ethAmount,
          nonce: nonce++
        });
        await tx.wait();
      }
    }

    // 批量给 VC 用户转账
    let funded = 0;
    for (let i = 0; i < this.vcUsers.length; i += this.config.batchSize) {
      const batch = this.vcUsers.slice(i, i + this.config.batchSize);
      const tasks = batch.map((user, idx) => ({
        signer: this.deployer,
        txData: { to: user.address, value: ethAmount, nonce: nonce + idx },
        label: `fund-${i + idx}`
      }));
      nonce += batch.length;

      const { success, failed } = await this.txSender.sendBatch(tasks);
      funded += success;

      const progress = Math.min(i + this.config.batchSize, this.vcUsers.length);
      log(`  转账进度: ${funded}/${progress} (失败: ${failed})`);
    }

    log(`ETH 分配完成: ${funded} 用户`);
  }

  async createVDRs() {
    log('--- 创建 VDR ---');

    const timestamp = Date.now();
    for (let i = 0; i < this.vdrCreators.length; i++) {
      const creator = this.vdrCreators[i];
      const name = `VDR_${i + 1}_${timestamp}`;
      const verifiers = [this.vcUsers[0].address];

      const factory = this.vdrFactory.connect(creator);
      const tx = await factory.createVDR(name, creator.address, verifiers);
      const receipt = await tx.wait();

      // 解析事件获取 VDR 地址
      const event = receipt.logs.find(log => {
        try {
          return this.vdrFactory.interface.parseLog(log)?.name === 'VDRCreated';
        } catch { return false; }
      });

      const parsed = this.vdrFactory.interface.parseLog(event);
      const vdrAddress = parsed.args.vdrAddress;
      const contract = new ethers.Contract(vdrAddress, this.vdrABI, this.deployer);

      this.vdrInstances.push({ address: vdrAddress, owner: creator.address, name, contract, creator });
      log(`  VDR ${i + 1}: ${name} -> ${vdrAddress.slice(0, 10)}...`);
    }

    log(`VDR 创建完成: ${this.vdrInstances.length} 个`);
  }

  async registerVCs() {
    log('--- 注册 VC ---');

    const totalVCs = this.vcUsers.length * this.vdrInstances.length * this.config.vcPerUser;
    log(`目标: ${totalVCs} 个 VC`);

    // 预获取所有用户的 nonce
    const userNonces = new Map();
    for (const user of this.vcUsers) {
      userNonces.set(user.address, await this.provider.getTransactionCount(user.address));
    }

    let registered = 0, failed = 0;

    for (let vdrIdx = 0; vdrIdx < this.vdrInstances.length; vdrIdx++) {
      const vdr = this.vdrInstances[vdrIdx];
      log(`  处理 VDR ${vdrIdx + 1}/${this.vdrInstances.length}: ${vdr.name}`);

      for (let userStart = 0; userStart < this.vcUsers.length; userStart += this.config.batchSize) {
        const userBatch = this.vcUsers.slice(userStart, userStart + this.config.batchSize);
        const tasks = [];
        const vcInfos = [];

        for (let bIdx = 0; bIdx < userBatch.length; bIdx++) {
          const user = userBatch[bIdx];
          const userIdx = userStart + bIdx;
          let nonce = userNonces.get(user.address);
          const vdrWithUser = vdr.contract.connect(user);

          for (let vcIdx = 0; vcIdx < this.config.vcPerUser; vcIdx++) {
            const vcIdStr = `vc_v${vdrIdx}_u${userIdx}_${vcIdx}_${Date.now()}_${Math.random()}`;
            const vcId = ethers.id(vcIdStr);
            const contentHash = ethers.keccak256(ethers.toUtf8Bytes(`c_${vcIdStr}`));
            const issuanceDate = Math.floor(Date.now() / 1000);

            tasks.push({
              signer: user,
              txData: {
                to: vdr.address,
                data: vdrWithUser.interface.encodeFunctionData('registerVC', [vcId, user.address, contentHash, issuanceDate]),
                nonce: nonce++
              },
              label: `vc-${userIdx}`
            });

            vcInfos.push({ vdrAddress: vdr.address, vdrIndex: vdrIdx, vcId, holder: user.address, issuer: user.address });
          }

          userNonces.set(user.address, nonce);
        }

        const { success, failed: batchFailed, results } = await this.txSender.sendBatch(tasks);

        results.forEach((r, idx) => {
          if (r.success) {
            this.allVCs.push(vcInfos[idx]);
            registered++;
          } else {
            failed++;
          }
        });

        const progress = Math.floor((registered + failed) / totalVCs * 100);
        if ((userStart + this.config.batchSize) % (this.config.batchSize * 2) === 0 || 
            userStart + this.config.batchSize >= this.vcUsers.length) {
          log(`    进度: ${registered} 成功 / ${registered + failed} 处理 (${progress}%)`);
        }
      }
    }

    log(`VC 注册完成: ${registered} 成功, ${failed} 失败`);
  }

  async disputeVCs() {
    log('--- 质疑 VC ---');

    if (this.allVCs.length === 0) {
      log('  无 VC 可质疑，跳过');
      return;
    }

    const vcsToDispute = randomSample(this.allVCs, this.config.disputeCount);
    let disputed = 0;

    // 获取 owner nonce
    const ownerNonces = new Map();
    for (const vdr of this.vdrInstances) {
      ownerNonces.set(vdr.creator.address, await this.provider.getTransactionCount(vdr.creator.address));
    }

    for (const vc of vcsToDispute) {
      const vdr = this.vdrInstances[vc.vdrIndex];
      const vdrWithOwner = vdr.contract.connect(vdr.creator);
      let nonce = ownerNonces.get(vdr.creator.address);

      try {
        const tx = await vdrWithOwner.disputeVC(vc.vcId, { nonce: nonce++ });
        await tx.wait();
        ownerNonces.set(vdr.creator.address, nonce);
        vc.disputed = true;
        disputed++;
      } catch (e) {
        log(`  质疑失败: ${e.message.slice(0, 60)}`);
      }
    }

    log(`质疑完成: ${disputed}/${vcsToDispute.length}`);
  }

  async revokeVCs() {
    log('--- 吊销 VC ---');

    const disputedVCs = this.allVCs.filter(vc => vc.disputed);
    if (disputedVCs.length === 0) {
      log('  无已质疑 VC，跳过');
      return;
    }

    const vcsToRevoke = randomSample(disputedVCs, this.config.revokeCount);
    let revoked = 0;

    const ownerNonces = new Map();
    for (const vdr of this.vdrInstances) {
      ownerNonces.set(vdr.creator.address, await this.provider.getTransactionCount(vdr.creator.address));
    }

    for (const vc of vcsToRevoke) {
      const vdr = this.vdrInstances[vc.vdrIndex];
      const vdrWithOwner = vdr.contract.connect(vdr.creator);
      let nonce = ownerNonces.get(vdr.creator.address);

      try {
        const tx = await vdrWithOwner.resolveDispute(vc.vcId, true, { nonce: nonce++ });
        await tx.wait();
        ownerNonces.set(vdr.creator.address, nonce);
        vc.revoked = true;
        revoked++;
      } catch (e) {
        log(`  吊销失败: ${e.message.slice(0, 60)}`);
      }
    }

    log(`吊销完成: ${revoked}/${vcsToRevoke.length}`);
  }

  async recheckAndRetry() {
    // 复查待确认交易
    const { recovered, stillPending } = await this.txSender.recheckPending();
    
    if (stillPending > 0) {
      log(`警告: 仍有 ${stillPending} 笔交易未确认`);
    }
  }

  printSummary() {
    log('--- 统计摘要 ---');
    log(`VDR 总数: ${this.vdrInstances.length}`);
    log(`VC 总数: ${this.allVCs.length}`);

    const disputed = this.allVCs.filter(vc => vc.disputed).length;
    const revoked = this.allVCs.filter(vc => vc.revoked).length;

    log(`已质疑: ${disputed}`);
    log(`已吊销: ${revoked}`);
    log(`活跃 VC: ${this.allVCs.length - revoked}`);

    for (let i = 0; i < this.vdrInstances.length; i++) {
      const vdr = this.vdrInstances[i];
      const vcs = this.allVCs.filter(vc => vc.vdrIndex === i);
      const d = vcs.filter(vc => vc.disputed).length;
      const r = vcs.filter(vc => vc.revoked).length;
      log(`  ${vdr.name}: ${vcs.length} VC (质疑: ${d}, 吊销: ${r})`);
    }
  }
}

// ============================================================
// 入口
// ============================================================

// 解析命令行参数
function parseArgs() {
  const args = process.argv.slice(2);
  const config = { ...CONFIG };

  for (const arg of args) {
    if (arg.startsWith('--users=')) {
      config.vcUserCount = parseInt(arg.split('=')[1], 10);
    } else if (arg.startsWith('--vdrs=')) {
      config.vdrCount = parseInt(arg.split('=')[1], 10);
    } else if (arg.startsWith('--batch=')) {
      config.batchSize = parseInt(arg.split('=')[1], 10);
    } else if (arg.startsWith('--vc-per-user=')) {
      config.vcPerUser = parseInt(arg.split('=')[1], 10);
    } else if (arg === '--help' || arg === '-h') {
      console.log(`
用法: node integration.js [options]

选项:
  --users=N       VC 用户数量 (默认: ${CONFIG.vcUserCount})
  --vdrs=N        VDR 数量 (默认: ${CONFIG.vdrCount})
  --batch=N       批量并发数 (默认: ${CONFIG.batchSize})
  --vc-per-user=N 每用户每VDR的VC数 (默认: ${CONFIG.vcPerUser})
  --help, -h      显示帮助
`);
      process.exit(0);
    }
  }

  return config;
}

const config = parseArgs();
const test = new VDRIntegrationTest(config);
test.run();
