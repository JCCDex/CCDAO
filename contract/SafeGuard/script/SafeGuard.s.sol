// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SafeGuard.sol";

/**
 * @title SafeGuardScript
 * @dev 部署和配置 SafeGuard 合约的脚本
 * @notice 使用方法:
 *   部署到本地网络: forge script script/SafeGuard.s.sol:SafeGuardScript --fork-url http://localhost:8545 --broadcast
 *   部署到测试网: forge script script/SafeGuard.s.sol:SafeGuardScript --fork-url $RPC_URL --broadcast --verify
 *   部署到主网: forge script script/SafeGuard.s.sol:SafeGuardScript --fork-url $MAINNET_RPC_URL --broadcast --verify --slow
 */
contract SafeGuardScript is Script {
    
    // 默认配置参数
    struct DeployConfig {
        address governance;
        uint256 nativePerTxLimit;    // 原生币单笔限额 (wei)
        uint256 tokenPerTxLimit;     // ERC20单笔限额 (最小单位)
        uint256 cooldownPeriod;      // 冷却时间 (秒)
        uint256 maxDailyTx;          // 每日最大交易数
        bool useWhitelist;           // 是否使用白名单模式
    }
    
    // 不同网络的配置
    mapping(uint256 => DeployConfig) public networkConfigs;
    
    // 部署的合约地址
    SafeGuard public safeGuard;
    
    function setUp() public {
        // 主网配置 (chainId: 1)
        networkConfigs[1] = DeployConfig({
            governance: address(0), // 需要设置实际的治理地址
            nativePerTxLimit: 10 ether,
            tokenPerTxLimit: 1000000 * 10**18, // 1M tokens
            cooldownPeriod: 1 hours,
            maxDailyTx: 20,
            useWhitelist: true
        });
        
        // Goerli 测试网配置 (chainId: 5)
        networkConfigs[5] = DeployConfig({
            governance: address(0), // 需要设置实际的治理地址
            nativePerTxLimit: 1 ether,
            tokenPerTxLimit: 100000 * 10**18, // 100K tokens
            cooldownPeriod: 30 minutes,
            maxDailyTx: 50,
            useWhitelist: false
        });
        
        // Sepolia 测试网配置 (chainId: 11155111)
        networkConfigs[11155111] = DeployConfig({
            governance: address(0), // 需要设置实际的治理地址
            nativePerTxLimit: 1 ether,
            tokenPerTxLimit: 100000 * 10**18,
            cooldownPeriod: 30 minutes,
            maxDailyTx: 50,
            useWhitelist: false
        });
        
        // 本地网络配置 (chainId: 31337)
        networkConfigs[31337] = DeployConfig({
            governance: address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8), // 本地测试地址
            nativePerTxLimit: 1 ether,
            tokenPerTxLimit: 10000 * 10**18,
            cooldownPeriod: 5 minutes,
            maxDailyTx: 100,
            useWhitelist: true
        });
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying SafeGuard with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);
        
        // 获取当前网络配置
        DeployConfig memory config = getNetworkConfig();
        
        // 如果治理地址未设置，使用部署者地址
        if (config.governance == address(0)) {
            config.governance = deployer;
            console.log("Using deployer as governance address:", deployer);
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署 SafeGuard 合约
        safeGuard = new SafeGuard(
            config.governance,
            config.nativePerTxLimit,
            config.tokenPerTxLimit
        );
        
        console.log("SafeGuard deployed at:", address(safeGuard));
        
        // 配置合约参数
        configureContract(config);
        
        vm.stopBroadcast();
        
        // 验证部署
        verifyDeployment(config);
        
        // 输出部署信息
        logDeploymentInfo();
    }
    
    function getNetworkConfig() internal view returns (DeployConfig memory) {
        uint256 chainId = block.chainid;
        
        if (networkConfigs[chainId].governance != address(0) || chainId == 31337) {
            return networkConfigs[chainId];
        }
        
        // 默认配置
        console.log("Using default configuration for chain ID:", chainId);
        return DeployConfig({
            governance: address(0),
            nativePerTxLimit: 1 ether,
            tokenPerTxLimit: 100000 * 10**18,
            cooldownPeriod: 1 hours,
            maxDailyTx: 10,
            useWhitelist: true
        });
    }
    
    function configureContract(DeployConfig memory config) internal {
        console.log("Configuring SafeGuard contract...");
        
        // 设置频率限制
        safeGuard.setFrequencyLimits(config.cooldownPeriod, config.maxDailyTx);
        console.log("Set cooldown period:", config.cooldownPeriod);
        console.log("Set max daily transactions:", config.maxDailyTx);
        
        // 设置地址控制模式
        safeGuard.setAddressControlMode(config.useWhitelist);
        console.log("Set whitelist mode:", config.useWhitelist);
        
        // 如果是白名单模式，添加一些初始地址
        if (config.useWhitelist && block.chainid == 31337) {
            // 本地测试网络添加一些测试地址到白名单
            address[] memory testAddresses = new address[](3);
            testAddresses[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // 本地测试地址1
            testAddresses[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // 本地测试地址2
            testAddresses[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // 本地测试地址3
            
            for (uint i = 0; i < testAddresses.length; i++) {
                safeGuard.addToWhitelist(testAddresses[i]);
                console.log("Added to whitelist:", testAddresses[i]);
            }
        }
    }
    
    function verifyDeployment(DeployConfig memory config) internal view {
        console.log("\n=== Verifying Deployment ===");
        
        require(address(safeGuard) != address(0), "SafeGuard not deployed");
        require(safeGuard.owner() != address(0), "Owner not set");
        require(safeGuard.governanceAddress() == config.governance, "Governance address mismatch");
        require(safeGuard.nativePerTxLimit() == config.nativePerTxLimit, "Native limit mismatch");
        require(safeGuard.tokenPerTxLimit() == config.tokenPerTxLimit, "Token limit mismatch");
        require(safeGuard.cooldownPeriod() == config.cooldownPeriod, "Cooldown period mismatch");
        require(safeGuard.maxDailyTx() == config.maxDailyTx, "Max daily tx mismatch");
        require(safeGuard.useWhitelist() == config.useWhitelist, "Whitelist mode mismatch");
        
        console.log("All verifications passed!");
    }
    
    function logDeploymentInfo() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("SafeGuard Address:", address(safeGuard));
        console.log("Owner:", safeGuard.owner());
        console.log("Governance:", safeGuard.governanceAddress());
        console.log("Native Per Tx Limit:", safeGuard.nativePerTxLimit());
        console.log("Token Per Tx Limit:", safeGuard.tokenPerTxLimit());
        console.log("Cooldown Period:", safeGuard.cooldownPeriod());
        console.log("Max Daily Tx:", safeGuard.maxDailyTx());
        console.log("Use Whitelist:", safeGuard.useWhitelist());
        console.log("Is Paused:", safeGuard.paused());
        
        // 检查预设的函数白名单
        console.log("\n=== Function Whitelist ===");
        bytes4[] memory defaultFunctions = new bytes4[](5);
        defaultFunctions[0] = 0xa9059cbb; // transfer
        defaultFunctions[1] = 0x23b872dd; // transferFrom
        defaultFunctions[2] = 0x42842e0e; // safeTransferFrom
        defaultFunctions[3] = 0xb88d4fde; // safeTransferFrom with data
        defaultFunctions[4] = 0x2eb2c2d6; // mintBatch
        
        for (uint i = 0; i < defaultFunctions.length; i++) {
            bool allowed = safeGuard.isFunctionAllowed(defaultFunctions[i]);
            console.log("Function", vm.toString(defaultFunctions[i]), "allowed:", allowed);
        }
    }
}

/**
 * @title SafeGuardManagementScript
 * @dev 管理已部署的 SafeGuard 合约的脚本
 */
contract SafeGuardManagementScript is Script {
    
    SafeGuard public safeGuard;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address safeGuardAddress = vm.envAddress("SAFEGUARD_ADDRESS");
        
        safeGuard = SafeGuard(safeGuardAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 在这里添加管理操作，例如：
        // addAddressesToWhitelist();
        // updateLimits();
        // addFunctionsToWhitelist();
        
        vm.stopBroadcast();
    }
    
    function addAddressesToWhitelist() internal {
        address[] memory addresses = new address[](2);
        addresses[0] = 0x1234567890123456789012345678901234567890; // 替换为实际地址
        addresses[1] = 0x0987654321098765432109876543210987654321; // 替换为实际地址
        
        for (uint i = 0; i < addresses.length; i++) {
            safeGuard.addToWhitelist(addresses[i]);
            console.log("Added to whitelist:", addresses[i]);
        }
    }
    
    function updateLimits() internal {
        safeGuard.setNativePerTxLimit(5 ether);
        safeGuard.setTokenPerTxLimit(500000 * 10**18);
        safeGuard.setFrequencyLimits(2 hours, 15);
        
        console.log("Updated limits");
    }
    
    function addFunctionsToWhitelist() internal {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = 0x095ea7b3; // approve
        functions[1] = 0x40c10f19; // mint
        
        for (uint i = 0; i < functions.length; i++) {
            safeGuard.addFunctionToWhitelist(functions[i]);
            console.log("Added function to whitelist:", vm.toString(functions[i]));
        }
    }
}