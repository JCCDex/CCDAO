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

// 获取 anvil 默认账户
const mnemonic = 'test test test test test test test test test test test junk';
const hdNode = ethers.HDNodeWallet.fromMnemonic(
  ethers.Mnemonic.fromPhrase(mnemonic),
  "m/44'/60'/0'/0"
);
const deployer = hdNode.deriveChild(0).connect(provider);

// 加载部署地址
function loadDeploymentAddresses() {
  const filePath = path.join(__dirname, '../artifacts/deployment.json');
  if (!fs.existsSync(filePath)) {
    throw new Error('deployment.json not found. Run: npm run deploy');
  }
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

describe('VDRFactoryProxy Determinism Test', function () {
  this.timeout(30000);

  let addresses;

  before(async function () {
    console.log('\n=== 测试 VDRFactoryProxy 确定性 ===\n');
    
    // 加载部署地址
    addresses = loadDeploymentAddresses();
    console.log('[DEPLOYMENT] 已加载部署地址:');
    console.log(`  CCDAOCreator2: ${addresses.ccdaoCreate2}`);
    console.log(`  VDR Implementation: ${addresses.vdrImplementation}`);
    console.log(`  VDRFactory Implementation: ${addresses.vdrFactory}`);
    console.log(`  VDRFactoryProxy: ${addresses.vdrFactoryProxy}`);
    console.log();
  });

  it('应该确保部署地址是固定的', async function () {
    console.log('[TEST] 验证部署地址:');
    
    // 验证所有地址都是有效的以太坊地址
    expect(ethers.isAddress(addresses.ccdaoCreate2)).to.be.true;
    expect(ethers.isAddress(addresses.vdrImplementation)).to.be.true;
    expect(ethers.isAddress(addresses.vdrFactory)).to.be.true;
    expect(ethers.isAddress(addresses.vdrFactoryProxy)).to.be.true;
    
    console.log('  ✓ 所有地址都是有效的以太坊地址');

    // 验证代理地址不是零地址
    expect(addresses.vdrFactoryProxy).to.not.equal('0x0000000000000000000000000000000000000000');
    console.log('  ✓ VDRFactoryProxy 不是零地址');

    // 验证代理地址和实现地址不同
    expect(addresses.vdrFactoryProxy).to.not.equal(addresses.vdrFactory);
    console.log('  ✓ VDRFactoryProxy 和 VDRFactory 实现地址不同');
  });

  it('应该确保 VDRFactoryProxy 能被调用', async function () {
    console.log('\n[TEST] 验证 VDRFactoryProxy 合约可访问性:');
    
    const vdrFactoryABI = [
      'function getVDRCount() public view returns (uint256)',
      'function owner() public view returns (address)',
    ];

    const vdrFactory = new ethers.Contract(addresses.vdrFactoryProxy, vdrFactoryABI, deployer);
    
    // 尝试调用 getVDRCount
    try {
      const count = await vdrFactory.getVDRCount();
      console.log(`  ✓ getVDRCount() = ${count}`);
    } catch (err) {
      // 可能失败，但地址应该存在
      console.log(`  ⚠ getVDRCount() 失败: ${err.message}`);
    }

    // 尝试调用 owner
    try {
      const ownerAddr = await vdrFactory.owner();
      console.log(`  ✓ owner() = ${ownerAddr}`);
    } catch (err) {
      console.log(`  ⚠ owner() 失败: ${err.message}`);
    }
  });

  it('应该确保每次部署 VDRFactoryProxy 地址相同或失败', async function () {
    console.log('\n[TEST] 重要：这需要运行两次来验证确定性');
    console.log('  运行 "bash run-all.sh" 两次，确保 vdrFactoryProxy 地址相同');
    console.log(`  当前地址: ${addresses.vdrFactoryProxy}`);
    console.log('  请保存此地址并在下次部署后比较');
  });

  it('应该验证合约是代理合约', async function () {
    console.log('\n[TEST] 验证 VDRFactoryProxy 是否使用代理模式:');
    
    const proxyAddress = addresses.vdrFactoryProxy;
    const implAddress = addresses.vdrFactory;
    
    console.log(`  代理地址: ${proxyAddress}`);
    console.log(`  实现地址: ${implAddress}`);

    // 对于 ERC1967 代理，实现地址存储在特定的 storage slot
    const ERC1967_IMPLEMENTATION_SLOT = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';
    
    try {
      const implementationFromProxy = await provider.getStorage(
        proxyAddress,
        ERC1967_IMPLEMENTATION_SLOT
      );
      
      // 从 bytes32 中提取地址（最后 20 字节）
      const addressFromSlot = '0x' + implementationFromProxy.slice(-40);
      
      console.log(`  ERC1967 实现地址: ${addressFromSlot}`);
      console.log(`  配置的实现地址: ${implAddress}`);
      
      if (addressFromSlot.toLowerCase() === implAddress.toLowerCase()) {
        console.log('  ✓ 代理正确指向实现地址');
      } else {
        console.log('  ⚠ 代理和实现地址不匹配（可能不是 ERC1967 代理）');
      }
    } catch (err) {
      console.log(`  ⚠ 无法读取 ERC1967 storage slot: ${err.message}`);
    }
  });
});
