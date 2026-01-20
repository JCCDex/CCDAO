// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";

interface ICCDAO_CREATE2 {
    function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address);
}

/**
 * @title VDR Upgrade Script (Stage 3+)
 * @dev Upgrades VDR implementations via CREATE2 for deterministic addresses
 * 
 * Prerequisites:
 * - Initial deployment (Stage 2) must be complete
 * - CCDAO_CREATE2 factory must be available
 * - VDRFactory Proxy address from Stage 2 deployment
 * 
 * When to use:
 * - When VDR contract code needs updates
 * - New version must be higher than current
 * - All existing VDR instances automatically upgraded via factory
 * 
 * What this script does:
 * 1. Deploy new VDR Implementation via CREATE2 (deterministic address)
 * 2. Call VDRFactory.setVDRImplementation() with new address
 * 3. All existing VDR proxies automatically point to new implementation
 * 
 * Configuration:
 * Set these environment variables:
 * export CCDAO_CREATE2=0x...                    # Factory address from Stage 1
 * export VDRF_FACTORY_PROXY=0x...              # Factory proxy from Stage 2
 * export VDR_IMPL_UPGRADE_SALT=0x...           # New salt for upgrade (optional)
 * 
 * Usage:
 * 
 * Local Anvil:
 * export CCDAO_CREATE2=0x5FbDB2315678afccb333f8a9c45b65d30c01f173
 * export VDRF_FACTORY_PROXY=0x...
 * export VDR_IMPL_UPGRADE_SALT=0x0000000000000000000000000000000000000000000000000000000000000010
 * forge script script/VDR_Upgrade.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 * 
 * Testnet:
 * export CCDAO_CREATE2=0x...
 * export VDRF_FACTORY_PROXY=0x...
 * export VDR_IMPL_UPGRADE_SALT=0x...
 * forge script script/VDR_Upgrade.s.sol \
 *   --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast
 * 
 * Important:
 * - Must be called by VDRFactory owner
 * - New implementation must have getVersion() method
 * - New implementation version must be higher than current
 * - Use unique SALT for each upgrade to avoid address collision
 */
contract VDRUpgrade is Script {
    // Default upgrade salt (should be unique for each upgrade)
    bytes32 constant DEFAULT_UPGRADE_SALT = 0x0000000000000000000000000000000000000000000000000000000000000010;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get required addresses
        address ccdaoCreate2 = vm.envAddress("CCDAO_CREATE2");
        address vdrfFactoryProxy = vm.envAddress("VDRF_FACTORY_PROXY");
        
        require(ccdaoCreate2 != address(0), "CCDAO_CREATE2 address not set");
        require(vdrfFactoryProxy != address(0), "VDRF_FACTORY_PROXY address not set");
        
        // Use default upgrade salt - modify constant to use different salt for each upgrade
        bytes32 upgradeSalt = DEFAULT_UPGRADE_SALT;

        console.log("==================================================");
        console.log("VDR Implementation Upgrade (Stage 3+)");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("CCDAO_CREATE2:", ccdaoCreate2);
        console.log("VDRFactory Proxy:", vdrfFactoryProxy);
        console.log("Chain ID:", block.chainid);
        console.log("");

        ICCDAO_CREATE2 factory = ICCDAO_CREATE2(ccdaoCreate2);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy new VDR implementation via CREATE2
        console.log("Step 1: Deploying New VDR Implementation via CREATE2...");
        bytes memory vdrBytecode = type(VDR).creationCode;
        bytes32 vdrBytecodeHash = keccak256(vdrBytecode);
        address newVdrImpl = factory.deploy(vdrBytecode, upgradeSalt);
        require(newVdrImpl != address(0), "VDR Implementation deployment failed");
        console.log("[OK] New VDR Implementation:", newVdrImpl);
        console.log("  Bytecode Hash:", vm.toString(vdrBytecodeHash));
        console.log("  Upgrade Salt:", vm.toString(upgradeSalt));

        // Step 2: Get factory instance and update implementation
        console.log("Step 2: Updating VDRFactory Implementation Pointer...");
        VDRFactory vdrfFactory = VDRFactory(vdrfFactoryProxy);
        
        // Step 3: Call setVDRImplementation
        // This will revert if:
        // - caller is not factory owner
        // - new implementation doesn't have getVersion() method
        // - new implementation version is not higher than current
        vdrfFactory.setVDRImplementation(newVdrImpl);
        console.log("[OK] Implementation updated successfully");

        vm.stopBroadcast();

        console.log("");
        console.log("==================================================");
        console.log("Upgrade Summary");
        console.log("==================================================");
        console.log("New VDR Implementation:", newVdrImpl);
        console.log("VDRFactory Proxy:", vdrfFactoryProxy);
        console.log("");
        console.log("Result: All existing VDR instances now use new implementation");
        console.log("");
        console.log("For next upgrade, use a different SALT:");
        console.log("  export VDR_IMPL_UPGRADE_SALT=0x...");
    }
}
