// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";

/**
 * @title VDR Upgrade Script
 * @dev Used for upgrading VDR implementation after initial deployment
 * 
 * This script is used for UPGRADE operations only. It:
 * 1. Deploys a new VDR Implementation contract
 * 2. Updates VDRFactory to point to the new implementation
 * 3. All existing VDR instances automatically use the new implementation
 * 
 * The VDRFactory proxy address remains the same - only the implementation changes.
 * 
 * Usage:
 * 
 * Local Anvil:
 * forge script script/VDR_Upgrade.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 * 
 * Sepolia Testnet:
 * forge script script/VDR_Upgrade.s.sol \
 *   --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify \
 *   --etherscan-api-key $ETHERSCAN_API_KEY
 * 
 * Production (Ethereum):
 * forge script script/VDR_Upgrade.s.sol \
 *   --rpc-url https://eth.llamarpc.com \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify \
 *   --etherscan-api-key $ETHERSCAN_API_KEY
 * 
 * Important:
 * - Set VDRF_FACTORY_PROXY address below (from initial deployment)
 * - The account running this script MUST be the factory owner
 * - New implementation must have a higher version number than current
 */
contract VDRUpgrade is Script {
    // ⚠️ UPDATE THIS with the VDRFactory proxy address from initial deployment
    address constant VDRF_FACTORY_PROXY = address(0); // TODO: Set this!

    function run() public {
        require(
            VDRF_FACTORY_PROXY != address(0),
            "Please set VDRF_FACTORY_PROXY address"
        );

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("VDR Implementation Upgrade");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("VDRFactory Proxy:", VDRF_FACTORY_PROXY);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy new VDR implementation
        console.log("Step 1: Deploying New VDR Implementation...");
        VDR newVdrImpl = new VDR();
        console.log("✓ New VDR Implementation:", address(newVdrImpl));

        // Step 2: Get factory instance and check current implementation
        console.log("Step 2: Checking Current Implementation...");
        VDRFactory factory = VDRFactory(VDRF_FACTORY_PROXY);
        
        // Get current implementation via ERC1967Utils (optional, for logging)
        console.log("Step 3: Updating Implementation...");
        
        // Step 3: Update factory to use new implementation
        // This will revert if:
        // - caller is not factory owner
        // - new implementation doesn't have getVersion() method
        // - new implementation version is not higher than current
        factory.setVDRImplementation(address(newVdrImpl));
        
        console.log("✓ Implementation updated successfully");

        vm.stopBroadcast();

        console.log("");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("Upgrade Summary");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("New VDR Implementation:", address(newVdrImpl));
        console.log("VDRFactory Proxy:", VDRF_FACTORY_PROXY);
        console.log("");
        console.log("Status: ✓ All existing VDR instances now use the new implementation");
        console.log("Existing contracts: All VDR instances are automatically upgraded");
        console.log("New contracts: factory.createVDR() will use the new implementation");
    }
}
