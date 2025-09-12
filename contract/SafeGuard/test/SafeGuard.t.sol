// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SafeGuard.sol";

contract SafeGuardTest is Test {
    SafeGuard public safeGuard;
    
    address public owner;
    address public governance;
    address public user1;
    address public user2;
    address public blacklistedUser;
    
    uint256 public constant NATIVE_LIMIT = 1 ether;
    uint256 public constant TOKEN_LIMIT = 1000 * 10**18;
    uint256 public constant COOLDOWN_PERIOD = 1 hours;
    uint256 public constant MAX_DAILY_TX = 10;
    
    // Events for testing
    event AddressAddedToWhitelist(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressAddedToBlacklist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);
    event FunctionAddedToWhitelist(bytes4 indexed selector);
    event FunctionRemovedFromWhitelist(bytes4 indexed selector);
    event NativePerTxLimitUpdated(uint256 nativePerTxLimit);
    event TokenPerTxLimitUpdated(uint256 tokenPerTxLimit);
    event FrequencyLimitsUpdated(uint256 cooldownPeriod, uint256 maxDailyTx);
    event DailyCountReset(address indexed account, uint256 day);
    event EmergencyPause(address indexed account);
    event EmergencyUnpause(address indexed account);
    
    function setUp() public {
        owner = makeAddr("owner");
        governance = makeAddr("governance");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        blacklistedUser = makeAddr("blacklistedUser");
        
        vm.startPrank(owner);
        safeGuard = new SafeGuard(governance, NATIVE_LIMIT, TOKEN_LIMIT);
        vm.stopPrank();
    }
    
    // ============ Constructor Tests ============
    
    function test_Constructor() view public {
        assertEq(safeGuard.owner(), owner);
        assertEq(safeGuard.governanceAddress(), governance);
        assertEq(safeGuard.nativePerTxLimit(), NATIVE_LIMIT);
        assertEq(safeGuard.tokenPerTxLimit(), TOKEN_LIMIT);
        assertEq(safeGuard.cooldownPeriod(), 1 hours);
        assertEq(safeGuard.maxDailyTx(), 10);
        assertEq(safeGuard.useWhitelist(), true);
        
        // Check initial function whitelist
        assertTrue(safeGuard.isFunctionAllowed(0xa9059cbb)); // transfer
        assertTrue(safeGuard.isFunctionAllowed(0x23b872dd)); // transferFrom
        assertTrue(safeGuard.isFunctionAllowed(0x42842e0e)); // safeTransferFrom
        assertTrue(safeGuard.isFunctionAllowed(0xb88d4fde)); // safeTransferFrom with data
        assertTrue(safeGuard.isFunctionAllowed(0x2eb2c2d6)); // mintBatch
    }
    
    // ============ Whitelist Management Tests ============
    
    function test_AddToWhitelist() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit AddressAddedToWhitelist(user1);
        safeGuard.addToWhitelist(user1);
        
        assertTrue(safeGuard.whitelist(user1));
        assertTrue(safeGuard.isAddressAllowed(user1));
        vm.stopPrank();
    }
    
    function test_AddToWhitelist_OnlyOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Not the owner");
        safeGuard.addToWhitelist(user2);
        vm.stopPrank();
    }
    
    function test_RemoveFromWhitelist() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        
        vm.expectEmit(true, false, false, false);
        emit AddressRemovedFromWhitelist(user1);
        safeGuard.removeFromWhitelist(user1);
        
        assertFalse(safeGuard.whitelist(user1));
        assertFalse(safeGuard.isAddressAllowed(user1));
        vm.stopPrank();
    }
    
    // ============ Blacklist Management Tests ============
    
    function test_AddToBlacklist() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit AddressAddedToBlacklist(blacklistedUser);
        safeGuard.addToBlacklist(blacklistedUser);
        
        assertTrue(safeGuard.blacklist(blacklistedUser));
        vm.stopPrank();
    }
    
    function test_RemoveFromBlacklist() public {
        vm.startPrank(owner);
        safeGuard.addToBlacklist(blacklistedUser);
        
        vm.expectEmit(true, false, false, false);
        emit AddressRemovedFromBlacklist(blacklistedUser);
        safeGuard.removeFromBlacklist(blacklistedUser);
        
        assertFalse(safeGuard.blacklist(blacklistedUser));
        vm.stopPrank();
    }
    
    function test_SetAddressControlMode() public {
        vm.startPrank(owner);
        safeGuard.setAddressControlMode(false);
        assertFalse(safeGuard.useWhitelist());
        
        safeGuard.setAddressControlMode(true);
        assertTrue(safeGuard.useWhitelist());
        vm.stopPrank();
    }
    
    function test_BlacklistMode() public {
        vm.startPrank(owner);
        safeGuard.setAddressControlMode(false); // Use blacklist mode
        safeGuard.addToBlacklist(blacklistedUser);
        
        assertFalse(safeGuard.isAddressAllowed(blacklistedUser));
        assertTrue(safeGuard.isAddressAllowed(user1)); // Not blacklisted
        vm.stopPrank();
    }
    
    // ============ Function Control Tests ============
    
    function test_AddFunctionToWhitelist() public {
        vm.startPrank(owner);
        bytes4 newSelector = 0x12345678;
        
        vm.expectEmit(true, false, false, false);
        emit FunctionAddedToWhitelist(newSelector);
        safeGuard.addFunctionToWhitelist(newSelector);
        
        assertTrue(safeGuard.isFunctionAllowed(newSelector));
        vm.stopPrank();
    }
    
    function test_RemoveFunctionFromWhitelist() public {
        vm.startPrank(owner);
        bytes4 selector = 0xa9059cbb; // transfer
        
        vm.expectEmit(true, false, false, false);
        emit FunctionRemovedFromWhitelist(selector);
        safeGuard.removeFunctionFromWhitelist(selector);
        
        assertFalse(safeGuard.isFunctionAllowed(selector));
        vm.stopPrank();
    }
    
    // ============ Limit Management Tests ============
    
    function test_SetNativePerTxLimit() public {
        vm.startPrank(owner);
        uint256 newLimit = 2 ether;
        
        vm.expectEmit(false, false, false, true);
        emit NativePerTxLimitUpdated(newLimit);
        safeGuard.setNativePerTxLimit(newLimit);
        
        assertEq(safeGuard.nativePerTxLimit(), newLimit);
        vm.stopPrank();
    }
    
    function test_SetTokenPerTxLimit() public {
        vm.startPrank(owner);
        uint256 newLimit = 2000 * 10**18;
        
        vm.expectEmit(false, false, false, true);
        emit TokenPerTxLimitUpdated(newLimit);
        safeGuard.setTokenPerTxLimit(newLimit);
        
        assertEq(safeGuard.tokenPerTxLimit(), newLimit);
        vm.stopPrank();
    }
    
    function test_SetFrequencyLimits() public {
        vm.startPrank(owner);
        uint256 newCooldown = 2 hours;
        uint256 newMaxDaily = 20;
        
        vm.expectEmit(false, false, false, true);
        emit FrequencyLimitsUpdated(newCooldown, newMaxDaily);
        safeGuard.setFrequencyLimits(newCooldown, newMaxDaily);
        
        assertEq(safeGuard.cooldownPeriod(), newCooldown);
        assertEq(safeGuard.maxDailyTx(), newMaxDaily);
        vm.stopPrank();
    }
    
    function test_ResetDailyCount() public {
        vm.startPrank(owner);
        uint256 currentDay = block.timestamp / 1 days;
        
        vm.expectEmit(true, false, false, true);
        emit DailyCountReset(user1, currentDay);
        safeGuard.resetDailyCount(user1);
        
        assertEq(safeGuard.lastResetDay(user1), currentDay);
        assertEq(safeGuard.dailyTxCount(user1), 0);
        vm.stopPrank();
    }
    
    // ============ Emergency Control Tests ============
    
    function test_EmergencyPause_Owner() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit EmergencyPause(owner);
        safeGuard.emergencyPause();
        
        assertTrue(safeGuard.paused());
        vm.stopPrank();
    }
    
    function test_EmergencyPause_Governance() public {
        vm.startPrank(governance);
        
        vm.expectEmit(true, false, false, false);
        emit EmergencyPause(governance);
        safeGuard.emergencyPause();
        
        assertTrue(safeGuard.paused());
        vm.stopPrank();
    }
    
    function test_EmergencyPause_Unauthorized() public {
        vm.startPrank(user1);
        vm.expectRevert("Not authorized");
        safeGuard.emergencyPause();
        vm.stopPrank();
    }
    
    function test_EmergencyUnpause() public {
        vm.startPrank(owner);
        safeGuard.emergencyPause();
        
        vm.expectEmit(true, false, false, false);
        emit EmergencyUnpause(owner);
        safeGuard.emergencyUnpause();
        
        assertFalse(safeGuard.paused());
        vm.stopPrank();
    }
    
    function test_SetGovernanceAddress() public {
        vm.startPrank(owner);
        address newGovernance = makeAddr("newGovernance");
        safeGuard.setGovernanceAddress(newGovernance);
        
        assertEq(safeGuard.governanceAddress(), newGovernance);
        vm.stopPrank();
    }
    
    // ============ CheckTransaction Tests ============
    
    function test_CheckTransaction_WhitelistMode_Success() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_WhitelistMode_AddressNotAllowed() public {
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        vm.expectRevert("Address not in whitelist");
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_BlacklistMode_Success() public {
        vm.startPrank(owner);
        safeGuard.setAddressControlMode(false); // Use blacklist mode
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_BlacklistMode_AddressBlacklisted() public {
        vm.startPrank(owner);
        safeGuard.setAddressControlMode(false); // Use blacklist mode
        safeGuard.addToBlacklist(blacklistedUser);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        vm.expectRevert("Address is blacklisted");
        safeGuard.checkTransaction(
            blacklistedUser,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_FunctionNotAllowed() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0x12345678, user2, 100); // Unknown function
        
        vm.expectRevert("Function not allowed");
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_NativeAmountExceedsLimit() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        vm.expectRevert("Native amount exceeds per-tx limit");
        safeGuard.checkTransaction(
            user1,
            2 ether, // Exceeds NATIVE_LIMIT (1 ether)
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_TokenAmountExceedsLimit() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 2000 * 10**18); // Exceeds TOKEN_LIMIT
        
        vm.expectRevert("Token amount exceeds per-tx limit");
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_DelegateCallNotAllowed() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        vm.expectRevert("DelegateCall operations are not allowed. Only CALL operations are permitted.");
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.DelegateCall,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    function test_CheckTransaction_ContractPaused() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        safeGuard.emergencyPause();
        vm.stopPrank();
        
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
        vm.expectRevert("Contract is paused");
        safeGuard.checkTransaction(
            user1,
            0.5 ether,
            data,
            Enum.Operation.Call,
            0, 0, 0, address(0), payable(address(0)), "", address(0)
        );
    }
    
    // ============ Frequency Control Tests ============
    
    // function test_CheckTransaction_CooldownPeriod() public {
    //     vm.startPrank(owner);
    //     safeGuard.addToWhitelist(user1);
    //     vm.stopPrank();
        
    //     // First transaction
    //     bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
        
    //     // Simulate successful transaction
    //     safeGuard.checkAfterExecution(bytes32(0), true);
        
    //     // Try immediate second transaction - should fail
    //     vm.expectRevert("Cooldown period not met");
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
        
    //     // Fast forward time
    //     vm.warp(block.timestamp + COOLDOWN_PERIOD + 1);
        
    //     // Should work now
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
    // }
    
    // function test_CheckTransaction_DailyTxLimit() public {
    //     vm.startPrank(owner);
    //     safeGuard.addToWhitelist(user1);
    //     safeGuard.setFrequencyLimits(0, 2); // No cooldown, max 2 daily tx
    //     vm.stopPrank();
        
    //     bytes memory data = abi.encodeWithSelector(0xa9059cbb, user2, 100 * 10**18);
        
    //     // First transaction
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
    //     safeGuard.checkAfterExecution(bytes32(0), true);
        
    //     // Second transaction
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
    //     safeGuard.checkAfterExecution(bytes32(0), true);
        
    //     // Third transaction should fail
    //     vm.expectRevert("Daily transaction limit exceeded");
    //     safeGuard.checkTransaction(
    //         user1, 0.5 ether, data, Enum.Operation.Call,
    //         0, 0, 0, address(0), payable(address(0)), "", address(0)
    //     );
    // }
    
    // ============ CheckAfterExecution Tests ============
    
    function test_CheckAfterExecution_Success() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        // Initial state
        assertEq(safeGuard.dailyTxCount(user1), 0);
        assertEq(safeGuard.lastTxTime(user1), 0);
        
        // Simulate successful transaction
        vm.startPrank(user1);
        safeGuard.checkAfterExecution(bytes32(0), true);
        vm.stopPrank();
        
        // Check updated state
        assertEq(safeGuard.dailyTxCount(user1), 1);
        assertEq(safeGuard.lastTxTime(user1), block.timestamp);
    }
    
    function test_CheckAfterExecution_Failed() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        // Simulate failed transaction
        vm.startPrank(user1);
        safeGuard.checkAfterExecution(bytes32(0), false);
        vm.stopPrank();
        
        // State should not be updated
        assertEq(safeGuard.dailyTxCount(user1), 0);
        assertEq(safeGuard.lastTxTime(user1), 0);
    }
    
    // ============ Query Function Tests ============
    
    function test_GetDailyStats() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        safeGuard.setFrequencyLimits(3600, 5); // 1 hour cooldown, 5 daily tx
        vm.stopPrank();
        
        // Execute a transaction
        vm.startPrank(user1);
        safeGuard.checkAfterExecution(bytes32(0), true);
        vm.stopPrank();
        
        (uint256 txCount, uint256 lastTx, uint256 lastReset, uint256 cooldownRemaining) = 
            safeGuard.getDailyStats(user1);
        
        assertEq(txCount, 1);
        assertEq(lastTx, block.timestamp);
        assertEq(lastReset, block.timestamp / 1 days);
        assertEq(cooldownRemaining, 3600); // Full cooldown period
        
        // Fast forward 1800 seconds (30 minutes)
        vm.warp(block.timestamp + 1800);
        
        (, , , cooldownRemaining) = safeGuard.getDailyStats(user1);
        assertEq(cooldownRemaining, 1800); // Half cooldown remaining
        
        // Fast forward past cooldown
        vm.warp(block.timestamp + 1801);
        
        (, , , cooldownRemaining) = safeGuard.getDailyStats(user1);
        assertEq(cooldownRemaining, 0); // No cooldown remaining
    }
    
    function test_DayReset() public {
        vm.startPrank(owner);
        safeGuard.addToWhitelist(user1);
        vm.stopPrank();
        
        // Execute transaction on day 1
        vm.startPrank(user1);
        safeGuard.checkAfterExecution(bytes32(0), true);
        vm.stopPrank();
        
        assertEq(safeGuard.dailyTxCount(user1), 1);
        
        // Fast forward to next day
        vm.warp(block.timestamp + 1 days);
        
        // Execute transaction on day 2
        vm.startPrank(user1);
        safeGuard.checkAfterExecution(bytes32(0), true);
        vm.stopPrank();
        
        // Daily count should reset
        assertEq(safeGuard.dailyTxCount(user1), 1);
        assertEq(safeGuard.lastResetDay(user1), block.timestamp / 1 days);
    }
}