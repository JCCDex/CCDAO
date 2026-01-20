// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CCDAOCreator2.sol";

/**
 * @title CCDAOCreator2Script
 * @dev Deployment script for the CCDAOCreator2 contract
 * 
 * Usage Examples:
 * 
 * ============================================================
 * 1. LOCAL ANVIL TEST (Recommended for testing)
 * ============================================================
 * # Terminal 1: Start Anvil
 * anvil
 *
 * # Terminal 2: Deploy to Anvil
 * forge script script/CCDAOCreator2.s.sol \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast \
 *   --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 *
 * ============================================================
 * 2. PRODUCTION NETWORK (Ethereum, Polygon, etc.)
 * ============================================================
 * # With environment variable
 * export PRIVATE_KEY=0x...
 * export RPC_URL=https://eth.llamarpc.com
 *
 * forge script script/CCDAOCreator2.s.sol \
 *   --rpc-url $RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   --verify
 *
 * # Or with .env file
 * # .env content:
 * # PRIVATE_KEY=0x...
 * # RPC_URL=https://eth.llamarpc.com
 *
 * forge script script/CCDAOCreator2.s.sol \
 *   --rpc-url $RPC_URL \
 *   --broadcast \
 *   --verify
 *
 * ============================================================
 * 3. DRY RUN (Simulate without broadcasting)
 * ============================================================
 * forge script script/CCDAOCreator2.s.sol \
 *   --rpc-url http://localhost:8545
 *
 * ============================================================
 * 4. VERIFY CONTRACT AFTER DEPLOYMENT
 * ============================================================
 * forge verify-contract <ADDRESS> CCDAOCreator2 \
 *   --verifier etherscan \
 *   --etherscan-api-key $ETHERSCAN_API_KEY \
 *   --compiler-version 0.8.20
 */
contract CCDAOCreator2Script is Script {
    
    /**
     * @dev Deploy the CCDAOCreator2 contract
     */
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy the CCDAOCreator2 contract
        CCDAOCreator2 creator = new CCDAOCreator2();
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("=================================");
        console.log("    CCDAOCreator2 Deployment    ");
        console.log("=================================");
        console.log("Contract Address:", address(creator));
        console.log("Owner Address:   ", creator.owner());
        console.log("Chain ID:        ", block.chainid);
        console.log("Block Number:    ", block.number);
        console.log("=================================");
    }
    
    /**
     * @dev Verify contract deployment and test basic functionality
     * Call this separately to verify the deployment worked
     */
    function verify(address deployedAddress) public view {
        CCDAOCreator2 creator = CCDAOCreator2(deployedAddress);
        
        console.log("=================================");
        console.log("   Verifying Deployment");
        console.log("=================================");
        console.log("Contract Owner:", creator.owner());
        console.log("Contract Balance:", address(creator).balance);
        console.log("=================================");
    }
}
