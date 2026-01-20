// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title VDR Initial Deployment Script (Stage 2)
 * @dev Deploys VDR core contracts AFTER CCDAO_CREATE2 is deployed
 * 
 * Deployment Stages:
 * Stage 1: Deploy CCDAO_CREATE2 factory (or get existing address)
 * Stage 2: This script - Deploy VDR infrastructure:
 *   - VDR Implementation contract
 *   - VDRFactory Implementation contract  
 *   - VDRFactory Proxy (behind ERC1967Proxy for upgrades)
 * Stage 3: Use VDRFactory.createVDR() to create VDR instances
 * 
 * For upgrades after Stage 2: Use VDR_Upgrade.s.sol
 * 
 * Prerequisites:
 * - CCDAO_CREATE2 must be deployed first (Stage 1)
 * - See ../../../contract/CCDAO_CREATE2/script/ for Stage 1
 * 
 * Usage Examples:
 * 
 * Local Anvil (Stage 1: CCDAO_CREATE2):
 * cd ../../CCDAO_CREATE2
 * forge script script/CCDAOCreator2.s.sol --rpc-url http://localhost:8545 --broadcast
 * 
 * Local Anvil (Stage 2: This script):
 * forge script script/VDR_Deploy_Initial.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 * 
 * Testnet (Stage 1 already deployed, just Stage 2):
 * forge script script/VDR_Deploy_Initial.s.sol \
 *   --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify \
 *   --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract VDRDeployInitial is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("VDR Initial Deployment");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy VDR implementation
        console.log("Step 1: Deploying VDR Implementation...");
        VDR vdrImpl = new VDR();
        console.log("✓ VDR Implementation:", address(vdrImpl));

        // Step 2: Deploy VDRFactory implementation
        console.log("Step 2: Deploying VDRFactory Implementation...");
        VDRFactory factoryImpl = new VDRFactory();
        console.log("✓ VDRFactory Implementation:", address(factoryImpl));

        // Step 3: Deploy VDRFactory proxy with initialization
        console.log("Step 3: Deploying VDRFactory Proxy...");
        bytes memory factoryInitData = abi.encodeCall(
            VDRFactory.initialize,
            (deployer, address(vdrImpl))
        );
        
        ERC1967Proxy factoryProxy = new ERC1967Proxy(address(factoryImpl), factoryInitData);
        console.log("✓ VDRFactory Proxy:", address(factoryProxy));

        // Step 4: Create example VDR instance (optional)
        console.log("Step 4: Creating Example VDR Instance...");
        VDRFactory factory = VDRFactory(address(factoryProxy));
        
        address vdrOwner = deployer;
        address[] memory dataManagers = new address[](1);
        dataManagers[0] = deployer;

        address vdrAddress = factory.createVDR(
            "Default VDR",
            vdrOwner,
            dataManagers
        );
        console.log("✓ VDR Instance:", vdrAddress);

        vm.stopBroadcast();

        console.log("");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("Deployment Summary");
        console.log("=".concat("=", "=", "=", "=", "=", "=", "=", "=", "=", "="));
        console.log("VDR Implementation:", address(vdrImpl));
        console.log("VDRFactory Implementation:", address(factoryImpl));
        console.log("VDRFactory Proxy:", address(factoryProxy));
        console.log("Default VDR Instance:", vdrAddress);
        console.log("");
        console.log("Next steps:");
        console.log("1. Save these addresses for reference");
        console.log("2. Use VDR_Upgrade.s.sol for future implementation upgrades");
        console.log("3. Use VDRFactory.createVDR() to create new VDR instances");
    }
}
