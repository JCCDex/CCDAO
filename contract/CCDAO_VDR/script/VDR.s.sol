// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title VDR Deployment Scripts - DEPRECATED
 * @dev This file is kept for reference only.
 * 
 * Please use the split scripts instead:
 * 
 * For INITIAL deployment (first-time setup):
 *   → Use: VDR_Deploy_Initial.s.sol
 *   → Deploys VDR Implementation, VDRFactory Implementation, and Proxy
 *   → Creates an example VDR instance
 * 
 * For UPGRADES (after initial deployment):
 *   → Use: VDR_Upgrade.s.sol
 *   → Only deploys new VDR Implementation
 *   → Updates VDRFactory to point to new implementation
 *   → All existing VDR instances automatically upgraded
 * 
 * Why split scripts?
 * - Initial deployment needs to set up everything
 * - Upgrades only need to deploy new implementation and update factory
 * - This avoids accidentally redeploying proxies (which would lose state)
 * - Clearer intent and safer operations
 */

// Legacy contract - kept for backward compatibility but marked as deprecated
contract DeployVDR is Script {
    function run() public {
        revert("DEPRECATED: Use VDR_Deploy_Initial.s.sol for initial deployment or VDR_Upgrade.s.sol for upgrades");
    }
}
