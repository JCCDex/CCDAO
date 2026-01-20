// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface ICCDAO_CREATE2 {
    function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address);
    function predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address);
}

/**
 * @title VDR Initial Deployment Script (Stage 2)
 * @dev Deploys VDR core contracts using CCDAO_CREATE2 for deterministic addresses
 * 
 * Deployment Stages:
 * Stage 1: Deploy CCDAO_CREATE2 factory (../../../CCDAO_CREATE2)
 * Stage 2: This script - Deploy VDR infrastructure via CREATE2:
 *   - VDR Implementation (deterministic address)
 *   - VDRFactory Implementation (deterministic address)
 *   - VDRFactory Proxy (deterministic address)
 * Stage 3: Use VDRFactory.createVDR() to create VDR instances
 * 
 * Key difference from standard deployment:
 * - Uses CCDAO_CREATE2.deploy() to generate deterministic addresses
 * - All contracts deployed via CREATE2 (salt-based)
 * - Same addresses across all networks with same salt values
 * 
 * Configuration:
 * Set environment variable with CCDAO_CREATE2 factory address:
 * export CCDAO_CREATE2=0x...
 * 
 * Or pass salt values to customize deployment (default: well-known salts)
 * export VDR_IMPL_SALT=0x...
 * export VDRF_IMPL_SALT=0x...
 * export VDRF_PROXY_SALT=0x...
 * 
 * Usage Examples:
 * 
 * Local Anvil:
 * export CCDAO_CREATE2=0x5FbDB2315678afccb333f8a9c45b65d30c01f173
 * export VDR_IMPL_SALT=0x0000000000000000000000000000000000000000000000000000000000000001
 * forge script script/VDR_Deploy_Initial.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 * 
 * Testnet:
 * export CCDAO_CREATE2=0x...
 * forge script script/VDR_Deploy_Initial.s.sol \
 *   --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast
 */
contract VDRDeployInitial is Script {
    // Default salt values for deterministic deployment (can be overridden via env)
    bytes32 constant DEFAULT_VDR_IMPL_SALT = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 constant DEFAULT_VDRF_IMPL_SALT = 0x0000000000000000000000000000000000000000000000000000000000000002;
    bytes32 constant DEFAULT_VDRF_PROXY_SALT = 0x0000000000000000000000000000000000000000000000000000000000000003;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get CCDAO_CREATE2 factory address
        address ccdaoCreate2 = vm.envAddress("CCDAO_CREATE2");
        require(ccdaoCreate2 != address(0), "CCDAO_CREATE2 address not set");
        
        // Get salt values (or use defaults)
        // For simplicity, use default salts - can be overridden by modifying constants
        bytes32 vdrImplSalt = DEFAULT_VDR_IMPL_SALT;
        bytes32 vdrfImplSalt = DEFAULT_VDRF_IMPL_SALT;
        bytes32 vdrfProxySalt = DEFAULT_VDRF_PROXY_SALT;

        console.log("==================================================");
        console.log("VDR Initial Deployment (Stage 2)");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("CCDAO_CREATE2 Factory:", ccdaoCreate2);
        console.log("Chain ID:", block.chainid);
        console.log("");

        ICCDAO_CREATE2 factory = ICCDAO_CREATE2(ccdaoCreate2);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy VDR implementation via CREATE2
        console.log("Step 1: Deploying VDR Implementation via CREATE2...");
        bytes memory vdrBytecode = type(VDR).creationCode;
        bytes32 vdrBytecodeHash = keccak256(vdrBytecode);
        address vdrImpl = factory.deploy(vdrBytecode, vdrImplSalt);
        require(vdrImpl != address(0), "VDR Implementation deployment failed");
        console.log("[OK] VDR Implementation:", vdrImpl);
        console.log("  Bytecode Hash:", vm.toString(vdrBytecodeHash));

        // Step 2: Deploy VDRFactory implementation via CREATE2
        console.log("Step 2: Deploying VDRFactory Implementation via CREATE2...");
        bytes memory vdrfBytecode = type(VDRFactory).creationCode;
        bytes32 vdrfBytecodeHash = keccak256(vdrfBytecode);
        address vdrfImpl = factory.deploy(vdrfBytecode, vdrfImplSalt);
        require(vdrfImpl != address(0), "VDRFactory Implementation deployment failed");
        console.log("[OK] VDRFactory Implementation:", vdrfImpl);
        console.log("  Bytecode Hash:", vm.toString(vdrfBytecodeHash));

        // Step 3: Deploy VDRFactory proxy via CREATE2
        console.log("Step 3: Deploying VDRFactory Proxy via CREATE2...");
        bytes memory factoryInitData = abi.encodeCall(
            VDRFactory.initialize,
            (deployer, vdrImpl)
        );
        
        bytes memory proxyBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(vdrfImpl, factoryInitData)
        );
        bytes32 proxyBytecodeHash = keccak256(proxyBytecode);
        address vdrfProxy = factory.deploy(proxyBytecode, vdrfProxySalt);
        require(vdrfProxy != address(0), "VDRFactory Proxy deployment failed");
        console.log("[OK] VDRFactory Proxy:", vdrfProxy);
        console.log("  Bytecode Hash:", vm.toString(proxyBytecodeHash));

        // Step 4: Create example VDR instance
        console.log("Step 4: Creating Example VDR Instance...");
        VDRFactory factoryProxy = VDRFactory(vdrfProxy);
        
        address vdrOwner = deployer;
        address[] memory dataManagers = new address[](1);
        dataManagers[0] = deployer;

        address vdrAddress = factoryProxy.createVDR(
            "Default VDR",
            vdrOwner,
            dataManagers
        );
        console.log("[OK] VDR Instance:", vdrAddress);

        vm.stopBroadcast();

        console.log("");
        console.log("==================================================");
        console.log("Deployment Summary");
        console.log("==================================================");
        console.log("VDR Implementation:", vdrImpl);
        console.log("VDRFactory Implementation:", vdrfImpl);
        console.log("VDRFactory Proxy:", vdrfProxy);
        console.log("Default VDR Instance:", vdrAddress);
        console.log("");
        console.log("Salt Values Used:");
        console.log("  VDR_IMPL_SALT:", vm.toString(vdrImplSalt));
        console.log("  VDRF_IMPL_SALT:", vm.toString(vdrfImplSalt));
        console.log("  VDRF_PROXY_SALT:", vm.toString(vdrfProxySalt));
        console.log("");
        console.log("Environment Variables to Save:");
        console.log("  export VDRF_FACTORY_PROXY=", vdrfProxy);
        console.log("  export VDR_IMPLEMENTATION=", vdrImpl);
        console.log("  export VDRF_IMPLEMENTATION=", vdrfImpl);
        console.log("");
        console.log("Next steps:");
        console.log("1. Save VDRF_FACTORY_PROXY for upgrades");
        console.log("2. Use VDR_Upgrade.s.sol for implementation upgrades");
        console.log("3. Use VDRFactory.createVDR() to create new instances");
    }
}
