// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";

/**
 * @title VDR Upgrade Script (Stage 3+)
 * @dev Upgrades VDR implementations with random addresses
 * 
 * Architecture Design:
 * - VDR Implementation: Deployed with random address (flexible per-org upgrades)
 * - Organizations can upgrade independently to different versions
 * 
 * Prerequisites:
 * - Initial deployment (Stage 2) must be complete
 * - VDRFactory Proxy address from Stage 2 deployment
 * 
 * When to use:
 * - When VDR contract code needs updates
 * - New version must be higher than current
 * - All existing VDR instances in this factory automatically upgraded
 * 
 * What this script does:
 * 1. Deploy new VDR Implementation via regular 'new' (random address)
 * 2. Call VDRFactory.setVDRImplementation() with new address
 * 3. All existing VDR proxies automatically point to new implementation
 * 
 * Configuration:
 * Set these environment variables:
 * export VDRF_FACTORY_PROXY=0x...              # Factory proxy from Stage 2
 * export PRIVATE_KEY=0x...
 * 
 * Usage:
 * 
 * Local Anvil:
 * export VDRF_FACTORY_PROXY=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
 * export PRIVATE_KEY=0x...
 * forge script script/VDR_Upgrade.s.sol:VDRUpgrade \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast
 * 
 * Testnet/Mainnet:
 * export VDRF_FACTORY_PROXY=0x...
 * export PRIVATE_KEY=0x...
 * forge script script/VDR_Upgrade.s.sol:VDRUpgrade \
 *   --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
 *   --broadcast
 * 
 * Important:
 * - Must be called by VDRFactory owner
 * - New implementation must have getVersion() method
 * - New implementation version must be higher than current
 * - Each upgrade creates new implementation at random address
 * - Different organizations maintain independent version history
 */
contract VDRUpgrade is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get required address
        address vdrfFactoryProxy = vm.envAddress("VDRF_FACTORY_PROXY");
        require(vdrfFactoryProxy != address(0), "VDRF_FACTORY_PROXY address not set");

        console.log("==================================================");
        console.log("VDR Implementation Upgrade (Stage 3+)");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("VDRFactory Proxy:", vdrfFactoryProxy);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy new VDR implementation (random address - flexible for upgrades)
        console.log("Step 1: Deploying New VDR Implementation (random address)...");
        VDR newVdrImpl = new VDR();
        console.log("[OK] New VDR Implementation:", address(newVdrImpl));

        // Step 2: Get factory instance and update implementation
        console.log("Step 2: Updating VDRFactory Implementation Pointer...");
        VDRFactory vdrfFactory = VDRFactory(vdrfFactoryProxy);
        
        // Step 3: Call setVDRImplementation
        // This will revert if:
        // - caller is not factory owner
        // - new implementation doesn't have getVersion() method
        // - new implementation version is not higher than current
        vdrfFactory.setVDRImplementation(address(newVdrImpl));
        console.log("[OK] Implementation updated successfully");

        vm.stopBroadcast();

        console.log("");
        console.log("==================================================");
        console.log("Upgrade Summary");
        console.log("==================================================");
        console.log("New VDR Implementation:", address(newVdrImpl));
        console.log("VDRFactory Proxy:", vdrfFactoryProxy);
        console.log("");
        console.log("Result: All existing VDR instances now use new implementation");
        console.log("Note: Implementation has random address - each org can upgrade independently");
        console.log("==================================================");
    }
}
