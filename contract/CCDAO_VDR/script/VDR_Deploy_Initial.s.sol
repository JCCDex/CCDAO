// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title VDR Initial Deployment Script (Stage 2)
 * @dev Deploys VDR core contracts with deterministic address architecture
 * 
 * Deployment Design:
 * Stage 1: Deploy CCDAO_CREATE2 factory (external, fixed address)
 * Stage 2: This script
 *   - VDR Implementation: Random address (flexible per-org upgrades)
 *   - VDRFactory Implementation: Random address
 *   - VDRFactory Proxy: CREATE2 with fixed salt (deterministic entry point)
 * Stage 3: Create VDR instances
 *   - VDR Instance Proxies: CREATE2 with DAO-name-based salt (deterministic per DAO)
 * 
 * Environment Variables:
 * export CCDAO_CREATE2=0x...  (address from Stage 1)
 * export PRIVATE_KEY=0x...
 * 
 * Usage:
 * forge script script/VDR_Deploy_Initial.s.sol:VDRDeployInitial \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast
 * 
 * Key Architecture Points:
 * - VDR Implementation has random address
 *   → Each organization can upgrade independently
 * - VDRFactory Proxy has deterministic address via CREATE2
 *   → Stable business entry point across all chains
 * - VDR Instance Proxies have deterministic addresses based on DAO name
 *   → Same DAO name = same proxy address across all chains
 */
contract VDRDeployInitial is Script {
    // Fixed salt for VDRFactory Proxy - ensures consistent address across chains
    bytes32 constant DEFAULT_VDRF_PROXY_SALT = 0x0000000000000000000000000000000000000000000000000000000000000003;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        address ccdaoCreate2 = vm.envAddress("CCDAO_CREATE2");
        require(ccdaoCreate2 != address(0), "CCDAO_CREATE2 address not set");

        console.log("==================================================");
        console.log("VDR Initial Deployment (Stage 2)");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("CCDAO_CREATE2 Factory:", ccdaoCreate2);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy VDR implementation (random address)
        console.log("Step 1: Deploying VDR Implementation (random address)...");
        VDR vdrImpl = new VDR();
        console.log("[OK] VDR Implementation:", address(vdrImpl));

        // Step 2: Deploy VDRFactory implementation (random address)
        console.log("Step 2: Deploying VDRFactory Implementation (random address)...");
        VDRFactory factoryImpl = new VDRFactory();
        console.log("[OK] VDRFactory Implementation:", address(factoryImpl));

        // Step 3: Deploy VDRFactory proxy via CREATE2 (deterministic)
        console.log("Step 3: Deploying VDRFactory Proxy via CREATE2...");
        bytes memory factoryInitData = abi.encodeCall(
            VDRFactory.initialize,
            (deployer, address(vdrImpl), ccdaoCreate2)
        );
        
        bytes memory proxyBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(address(factoryImpl), factoryInitData)
        );

        // Call CCDAO_CREATE2.deploy to deploy the proxy with deterministic address
        address vdrfProxy = _callCreate2(ccdaoCreate2, proxyBytecode, DEFAULT_VDRF_PROXY_SALT);
        require(vdrfProxy != address(0), "VDRFactory Proxy deployment failed");
        console.log("[OK] VDRFactory Proxy:", vdrfProxy);

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
        require(vdrAddress != address(0), "VDR instance creation failed");
        console.log("[OK] VDR Instance (deterministic per name):", vdrAddress);

        vm.stopBroadcast();

        console.log("");
        console.log("==================================================");
        console.log("Deployment Summary");
        console.log("==================================================");
        console.log("VDR Implementation (random):", address(vdrImpl));
        console.log("VDRFactory Implementation (random):", address(factoryImpl));
        console.log("VDRFactory Proxy (CREATE2 - fixed):", vdrfProxy);
        console.log("VDR Instance (CREATE2 - per name):", vdrAddress);
        console.log("");
        console.log("Architecture Notes:");
        console.log("  1. VDR Implementation has random address");
        console.log("     - Each organization can upgrade independently");
        console.log("  2. VDRFactory Proxy has deterministic address");
        console.log("     - Stable entry point across all chains");
        console.log("  3. VDR Instance Proxy has deterministic address");
        console.log("     - Based on DAO name (keccak256 hash)");
        console.log("");
        console.log("Next: Save for Stage 3");
        console.log("  export VDRF_FACTORY_PROXY=", vdrfProxy);
        console.log("==================================================");
    }

    /**
     * @dev Call CCDAO_CREATE2.deploy via low-level call
     */
    function _callCreate2(
        address create2Factory,
        bytes memory bytecode,
        bytes32 salt
    ) internal returns (address) {
        // Encode the function call: deploy(bytecode, salt)
        bytes memory callData = abi.encodeWithSignature(
            "deploy(bytes,bytes32)",
            bytecode,
            salt
        );
        
        (bool success, bytes memory result) = create2Factory.call(callData);
        require(success, string(abi.encodePacked("CREATE2 call failed: ", result)));
        
        return abi.decode(result, (address));
    }
}
