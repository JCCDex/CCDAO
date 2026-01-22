import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 连接到本地 anvil 链
const ANVIL_RPC = 'http://127.0.0.1:8545';
const provider = new ethers.JsonRpcProvider(ANVIL_RPC);

// 获取 anvil 默认账户（使用 HDNodeWallet）
const mnemonic = 'test test test test test test test test test test test junk';
const hdNode = ethers.HDNodeWallet.fromMnemonic(
  ethers.Mnemonic.fromPhrase(mnemonic),
  "m/44'/60'/0'/0"
);
const deployer = hdNode.deriveChild(0).connect(provider);

console.log('Deployer:', deployer.address);

// 全局 nonce 计数器
let currentNonce = null;

async function initNonce() {
  currentNonce = await provider.getTransactionCount(deployer.address);
  console.log(`[INIT] Starting nonce: ${currentNonce}`);
}

async function deployContract(name, abi, bytecode, args = []) {
  console.log(`\n[DEPLOY] ${name}...`);
  console.log(`  [NONCE] ${currentNonce}`);
  
  const factory = new ethers.ContractFactory(abi, bytecode, deployer);
  const contract = await factory.deploy(...args, { nonce: currentNonce });
  currentNonce++;
  
  await contract.waitForDeployment();
  
  const address = await contract.getAddress();
  console.log(`[OK] ${name} deployed at: ${address}`);
  
  return address;
}

async function deployWithCreate2(name, bytecode, salt, create2Address, signer) {
  console.log(`\n[DEPLOY] ${name} via CREATE2...`);
  
  const create2Contract = new ethers.Contract(
    create2Address,
    [
      'function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address)',
      'function predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address)'
    ],
    signer
  );
  
  const bytecodeHash = ethers.keccak256(bytecode);
  const predictedAddress = await create2Contract.predictAddress(salt, bytecodeHash);
  console.log(`  [PREDICT] ${predictedAddress}`);
  console.log(`  [SALT] ${salt}`);
  console.log(`  [NONCE] ${currentNonce}`);
  
  // 检查地址是否已有代码
  const existingCode = await provider.getCode(predictedAddress);
  if (existingCode !== '0x') {
    console.log(`[SKIP] CREATE2 地址已部署: ${predictedAddress}`);
    return predictedAddress;
  }
  
  // 地址未部署，执行 CREATE2
  const tx = await create2Contract.deploy(bytecode, salt, { nonce: currentNonce });
  currentNonce++;
  
  await tx.wait();
  
  console.log(`[OK] ${name} deployed at: ${predictedAddress}`);
  return predictedAddress;
}

async function main() {
  try {
    // 初始化 nonce
    await initNonce();
    
    // 检查连接
    const balance = await provider.getBalance(deployer.address);
    console.log(`Deployer balance: ${ethers.formatEther(balance)} ETH\n`);

    console.log('=== 开始部署合约 ===\n');
    
    // 动态判断路径
    const toolsDir = path.dirname(__dirname);           // CCDAO_VDR/tools
    const vdrDir = path.dirname(toolsDir);              // CCDAO_VDR
    const contractDir = path.dirname(vdrDir);           // contract
    const create2Dir = path.join(contractDir, 'CCDAO_CREATE2');
    
    console.log(`[INFO] VDR Dir: ${vdrDir}`);
    console.log(`[INFO] CREATE2 Dir: ${create2Dir}\n`);
    
    const ccdaoCreate2Json = JSON.parse(
      fs.readFileSync(path.join(create2Dir, 'out/CCDAOCreator2.sol/CCDAOCreator2.json'), 'utf8')
    );
    
    const vdrFactoryJson = JSON.parse(
      fs.readFileSync(path.join(vdrDir, 'out/VDRFactory.sol/VDRFactory.json'), 'utf8')
    );
    
    const vdrJson = JSON.parse(
      fs.readFileSync(path.join(vdrDir, 'out/VDR.sol/VDR.json'), 'utf8')
    );

    const erc1967ProxyJson = JSON.parse(
      fs.readFileSync(path.join(vdrDir, 'out/ERC1967Proxy.sol/ERC1967Proxy.json'), 'utf8')
    );

    const deploymentJsonPath = path.join(__dirname, '../artifacts/deployment.json');
    const artifactsDir = path.dirname(deploymentJsonPath);
    
    // 确保 artifacts 目录存在
    if (!fs.existsSync(artifactsDir)) {
      fs.mkdirSync(artifactsDir, { recursive: true });
    }

    // ========== 第 1 步：部署或复用 CCDAOCreator2 ==========
    console.log('[1/5] 部署 CREATE2 工厂合约');
    
    let ccdaoCreate2Address;
    
    if (fs.existsSync(deploymentJsonPath)) {
      const existing = JSON.parse(fs.readFileSync(deploymentJsonPath, 'utf8'));
      if (existing.ccdaoCreate2) {
        const existingCode = await provider.getCode(existing.ccdaoCreate2);
        if (existingCode !== '0x') {
          console.log(`[REUSE] 复用已存在的 CCDAOCreator2 at ${existing.ccdaoCreate2}`);
          ccdaoCreate2Address = existing.ccdaoCreate2;
        } else {
          console.log(`[REDEPLOY] 记录的 factory 地址已不存在，重新部署`);
          ccdaoCreate2Address = await deployContract(
            'CCDAOCreator2',
            ccdaoCreate2Json.abi,
            ccdaoCreate2Json.bytecode.object,
            []
          );
        }
      } else {
        console.log(`[NEW] 部署新的 CCDAOCreator2`);
        ccdaoCreate2Address = await deployContract(
          'CCDAOCreator2',
          ccdaoCreate2Json.abi,
          ccdaoCreate2Json.bytecode.object,
          []
        );
      }
    } else {
      console.log(`[NEW] 首次部署 CCDAOCreator2`);
      ccdaoCreate2Address = await deployContract(
        'CCDAOCreator2',
        ccdaoCreate2Json.abi,
        ccdaoCreate2Json.bytecode.object,
        []
      );
    }

    // ========== 第 2 步：部署 VDR 实现合约（使用 CREATE2 确保地址固定）==========
    console.log('\n[2/5] 部署 VDR 实现合约（CREATE2）');
    
    const vdrImplSalt = ethers.keccak256(ethers.toUtf8Bytes('VDR_impl_v1'));
    const vdrImplementationAddress = await deployWithCreate2(
      'VDR (Implementation)',
      vdrJson.bytecode.object,
      vdrImplSalt,
      ccdaoCreate2Address,
      deployer
    );

    // ========== 第 3 步：部署 VDRFactory 实现合约（使用 CREATE2 确保地址固定）==========
    console.log('\n[3/5] 部署 VDRFactory 实现合约（CREATE2）');
    
    const vdrFactoryImplSalt = ethers.keccak256(ethers.toUtf8Bytes('VDRFactory_impl_v1'));
    const vdrFactoryImplementationAddress = await deployWithCreate2(
      'VDRFactory (Implementation)',
      vdrFactoryJson.bytecode.object,
      vdrFactoryImplSalt,
      ccdaoCreate2Address,
      deployer
    );

    // ========== 第 4 步：通过 CREATE2 部署 VDRFactoryProxy ==========
    console.log('\n[4/5] 通过 CREATE2 部署 VDRFactoryProxy');
    
    // 准备初始化数据
    const iface = new ethers.Interface(vdrFactoryJson.abi);
    const initCall = iface.encodeFunctionData('initialize', [
      deployer.address,
      vdrFactoryImplementationAddress,
      ccdaoCreate2Address
    ]);

    // 构建 Proxy bytecode（包含初始化参数）
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
    
    // 固定的 salt
    const vdrFactoryProxySalt = ethers.keccak256(ethers.toUtf8Bytes('VDRFactoryProxy_v1'));
    
    const vdrFactoryAddress = await deployWithCreate2(
      'VDRFactory (Proxy)',
      proxyBytecode,
      vdrFactoryProxySalt,
      ccdaoCreate2Address,
      deployer
    );

    // ========== 第 5 步：保存部署地址 ==========
    console.log('\n[5/5] 保存部署地址');
    
    const deploymentAddresses = {
      ccdaoCreate2: ccdaoCreate2Address,
      vdrImplementation: vdrImplementationAddress,
      vdrFactory: vdrFactoryImplementationAddress,
      vdrFactoryProxy: vdrFactoryAddress,
      deployer: deployer.address,
      deploymentTime: new Date().toISOString()
    };

    fs.writeFileSync(deploymentJsonPath, JSON.stringify(deploymentAddresses, null, 2));
    console.log(`[OK] 部署地址已保存到: ${deploymentJsonPath}`);
    
    console.log('\n=== 部署完成 ===');
    console.log(JSON.stringify(deploymentAddresses, null, 2));

    return deploymentAddresses;

  } catch (error) {
    console.error('[FAIL] 部署失败:', error.message);
    if (error.data) {
      console.error('[ERROR_DATA]', error.data);
    }
    process.exit(1);
  }
}

main().catch(console.error);
