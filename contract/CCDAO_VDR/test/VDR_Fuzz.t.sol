// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VDR.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/libraries/VDRConstants.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";

/**
 * @title VDR Fuzz Tests
 * @dev Comprehensive fuzz testing for VDR contract
 * 
 * Fuzz testing generates random inputs to find edge cases and vulnerabilities.
 * Run with: forge test --match-contract VDRFuzzTest -vvv
 * Increase runs: forge test --match-contract VDRFuzzTest --fuzz-runs 10000
 */
contract VDRFuzzTest is Test {
    VDR vdrImplementation;
    ERC1967Proxy vdrProxy;
    VDR vdr;
    
    MockERC20 mockERC20;
    MockERC721 mockERC721;
    
    address owner;
    address admin;
    address issuer1;
    address holder1;

    function setUp() public {
        vdrImplementation = new VDR();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        
        owner = address(0x1);
        admin = address(0x2);
        issuer1 = address(0x3);
        holder1 = address(0x6);

        // Set block timestamp to avoid underflow
        vm.warp(365 days);

        address[] memory verifiers = new address[](1);
        verifiers[0] = issuer1;

        bytes memory initData = abi.encodeCall(
            VDR.initialize,
            ("Fuzz Test VDR", owner, verifiers)
        );

        vdrProxy = new ERC1967Proxy(address(vdrImplementation), initData);
        vdr = VDR(address(vdrProxy));

        vm.prank(owner);
        vdr.setAdmin(admin);
        
        // Setup official tokens
        vm.prank(owner);
        vdr.setOfficialERC20(address(mockERC20));
        vm.prank(owner);
        vdr.setOfficialERC721(address(mockERC721));
    }

    // ============ VC Registration Fuzz Tests ============

    /**
     * @dev Fuzz test: registerVC with random valid inputs
     * Tests that registration always succeeds with valid parameters
     */
    function testFuzz_RegisterVC_ValidInputs(
        bytes32 vcId,
        address holder,
        bytes32 vcType,
        bytes32 contentHash,
        uint256 issuanceDateOffset
    ) public {
        // Filter invalid inputs
        vm.assume(vcId != bytes32(0));
        vm.assume(holder != address(0));
        vm.assume(contentHash != bytes32(0));
        
        // Bound issuanceDate to valid range (1 to current timestamp)
        uint256 issuanceDate = bound(issuanceDateOffset, 1, block.timestamp);
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder, vcType, contentHash, issuanceDate);
        
        // Verify registration
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.vcId, vcId);
        assertEq(vc.issuer, issuer1);
        assertEq(vc.holder, holder);
        assertEq(vc.vcType, vcType);
        assertEq(vc.contentHash, contentHash);
        assertEq(vc.issuanceDate, issuanceDate);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Active));
    }

    /**
     * @dev Fuzz test: registerVC with random issuer address
     * Tests that anyone can register VCs
     */
    function testFuzz_RegisterVC_AnyIssuer(address randomIssuer) public {
        vm.assume(randomIssuer != address(0));
        
        bytes32 vcId = keccak256(abi.encodePacked("fuzz-issuer", randomIssuer));
        bytes32 contentHash = keccak256("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(randomIssuer);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuer, randomIssuer);
    }

    /**
     * @dev Fuzz test: vcType can be any bytes32 value
     */
    function testFuzz_RegisterVC_AnyVcType(bytes32 vcType) public {
        bytes32 vcId = keccak256(abi.encodePacked("fuzz-type", vcType));
        bytes32 contentHash = keccak256("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, vcType, contentHash, issuanceDate);
        
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.vcType, vcType);
    }

    /**
     * @dev Fuzz test: issuanceDate boundary - exactly at block.timestamp
     */
    function testFuzz_RegisterVC_IssuanceDateBoundary(uint256 warpTime) public {
        // Bound warp time to reasonable range
        warpTime = bound(warpTime, 365 days, 3650 days);
        vm.warp(warpTime);
        
        bytes32 vcId = keccak256(abi.encodePacked("fuzz-boundary", warpTime));
        bytes32 contentHash = keccak256("content");
        
        // Test exact boundary: issuanceDate == block.timestamp
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp);
        
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuanceDate, block.timestamp);
        assertEq(vc.registrationTime, block.timestamp);
    }

    // ============ vcCount Invariant Tests ============

    /**
     * @dev Fuzz test: vcCount invariant after multiple registrations
     * Invariant: vcCount == number of registered VCs
     */
    function testFuzz_VCCount_AfterRegistrations(uint8 count) public {
        // Bound to reasonable range
        count = uint8(bound(count, 1, 50));
        
        for (uint8 i = 0; i < count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("count-test", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        assertEq(vdr.getTotalVCCount(), count);
    }

    /**
     * @dev Fuzz test: vcCount invariant after registrations and revocations
     * Invariant: vcCount == registrations - revocations
     */
    function testFuzz_VCCount_AfterRegistrationsAndRevocations(
        uint8 registerCount,
        uint8 revokeCount
    ) public {
        // Bound to reasonable range
        registerCount = uint8(bound(registerCount, 1, 30));
        revokeCount = uint8(bound(revokeCount, 0, registerCount));
        
        bytes32[] memory vcIds = new bytes32[](registerCount);
        
        // Register VCs
        for (uint8 i = 0; i < registerCount; i++) {
            vcIds[i] = keccak256(abi.encodePacked("revoke-test", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcIds[i], holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        assertEq(vdr.getTotalVCCount(), registerCount);
        
        // Revoke some VCs
        for (uint8 i = 0; i < revokeCount; i++) {
            vm.prank(issuer1);
            vdr.revokeVC(vcIds[i]);
        }
        
        // Invariant check
        assertEq(vdr.getTotalVCCount(), registerCount - revokeCount);
    }

    /**
     * @dev Fuzz test: vcCount never underflows (stays >= 0)
     */
    function testFuzz_VCCount_NeverUnderflows(uint8 actions) public {
        actions = uint8(bound(actions, 1, 20));
        
        uint256 registered = 0;
        uint256 revoked = 0;
        
        for (uint8 i = 0; i < actions; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("underflow-test", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content", i));
            
            // Always register
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
            registered++;
            
            // Sometimes revoke
            if (i % 2 == 0 && registered > revoked) {
                vm.prank(issuer1);
                vdr.revokeVC(vcId);
                revoked++;
            }
        }
        
        // vcCount should never be negative
        assertTrue(vdr.getTotalVCCount() >= 0);
        assertEq(vdr.getTotalVCCount(), registered - revoked);
    }

    // ============ Index Consistency Tests ============

    /**
     * @dev Fuzz test: issuerVCs index consistency
     * Invariant: getIssuerVCs returns all VCs issued by an address
     */
    function testFuzz_IssuerIndex_Consistency(uint8 issuer1Count, uint8 issuer2Count) public {
        issuer1Count = uint8(bound(issuer1Count, 0, 20));
        issuer2Count = uint8(bound(issuer2Count, 0, 20));
        
        address issuer2 = address(0x4);
        
        // Register VCs for issuer1
        for (uint8 i = 0; i < issuer1Count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("issuer1", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content1", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        // Register VCs for issuer2
        for (uint8 i = 0; i < issuer2Count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("issuer2", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content2", i));
            
            vm.prank(issuer2);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        // Verify index lengths
        assertEq(vdr.getIssuerVCs(issuer1).length, issuer1Count);
        assertEq(vdr.getIssuerVCs(issuer2).length, issuer2Count);
    }

    /**
     * @dev Fuzz test: holderVCs index consistency
     */
    function testFuzz_HolderIndex_Consistency(uint8 holder1Count, uint8 holder2Count) public {
        holder1Count = uint8(bound(holder1Count, 0, 20));
        holder2Count = uint8(bound(holder2Count, 0, 20));
        
        address holder2 = address(0x7);
        
        // Register VCs for holder1
        for (uint8 i = 0; i < holder1Count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("holder1", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content1", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        // Register VCs for holder2
        for (uint8 i = 0; i < holder2Count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("holder2", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content2", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder2, bytes32(0), contentHash, block.timestamp - 1 days);
        }
        
        // Verify index lengths
        assertEq(vdr.getHolderVCs(holder1).length, holder1Count);
        assertEq(vdr.getHolderVCs(holder2).length, holder2Count);
    }

    // ============ Dispute Tests ============

    /**
     * @dev Fuzz test: disputedVCs tracking consistency
     */
    function testFuzz_DisputedVCs_Tracking(uint8 disputeCount, uint8 resolveCount) public {
        disputeCount = uint8(bound(disputeCount, 1, 20));
        resolveCount = uint8(bound(resolveCount, 0, disputeCount));
        
        // Give issuer1 tokens to dispute
        mockERC20.mint(issuer1, 10000 * 10**18);
        
        bytes32[] memory vcIds = new bytes32[](disputeCount);
        
        // Register and dispute VCs
        for (uint8 i = 0; i < disputeCount; i++) {
            vcIds[i] = keccak256(abi.encodePacked("dispute-track", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcIds[i], holder1, bytes32(0), contentHash, block.timestamp - 1 days);
            
            vm.prank(issuer1);
            vdr.disputeVC(vcIds[i]);
        }
        
        assertEq(vdr.getDisputedVCs().length, disputeCount);
        
        // Resolve some disputes
        for (uint8 i = 0; i < resolveCount; i++) {
            vm.prank(admin);
            vdr.resolveDispute(vcIds[i], i % 2 == 0); // Alternate between revoke and restore
        }
        
        // Verify disputed VCs count
        assertEq(vdr.getDisputedVCs().length, disputeCount - resolveCount);
    }

    // ============ Member Management Tests ============

    /**
     * @dev Fuzz test: member management with random addresses
     */
    function testFuzz_MemberManagement(address[] calldata members) public {
        vm.assume(members.length <= 50);
        
        uint256 addedCount = 0;
        
        for (uint256 i = 0; i < members.length; i++) {
            // Skip zero address and duplicates
            if (members[i] == address(0)) continue;
            if (vdr.isMember(members[i])) continue;
            
            vm.prank(admin);
            vdr.addMember(members[i], VDRConstants.VERIFIER_ROLE);
            addedCount++;
        }
        
        // Initial members: issuer1 + admin = 2
        // Note: getMemberCount includes all members added during setup
        assertTrue(vdr.getMemberCount() >= addedCount);
    }

    /**
     * @dev Fuzz test: role assignment
     */
    function testFuzz_RoleAssignment(address member, bytes32 role) public {
        vm.assume(member != address(0));
        vm.assume(!vdr.isMember(member));
        
        vm.prank(admin);
        vdr.addMember(member, role);
        
        assertTrue(vdr.isMember(member));
        assertTrue(vdr.hasMemberRole(member, role));
    }

    // ============ Revocation Permission Tests ============

    /**
     * @dev Fuzz test: only authorized users can revoke
     */
    function testFuzz_RevokeVC_Authorization(address caller) public {
        vm.assume(caller != address(0));
        vm.assume(caller != issuer1);
        vm.assume(caller != admin);
        vm.assume(caller != owner);
        vm.assume(!vdr.hasMemberRole(caller, VDRConstants.ADMIN_ROLE));
        
        bytes32 vcId = keccak256(abi.encodePacked("auth-test", caller));
        bytes32 contentHash = keccak256("content");
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        
        // Unauthorized caller should fail
        vm.prank(caller);
        vm.expectRevert("VDR: only issuer, admin or owner can revoke");
        vdr.revokeVC(vcId);
    }

    // ============ Status Transition Tests ============

    /**
     * @dev Fuzz test: status transitions are valid
     */
    function testFuzz_StatusTransitions(bool shouldDispute, bool shouldResolve, bool resolveWithRevoke) public {
        mockERC20.mint(issuer1, 10000 * 10**18);
        
        bytes32 vcId = keccak256(abi.encodePacked("status-test", shouldDispute, shouldResolve));
        bytes32 contentHash = keccak256("content");
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
        
        // Initial status should be Active
        assertEq(uint256(vdr.getVC(vcId).status), uint256(VDRConstants.VCStatus.Active));
        
        if (shouldDispute) {
            vm.prank(issuer1);
            vdr.disputeVC(vcId);
            assertEq(uint256(vdr.getVC(vcId).status), uint256(VDRConstants.VCStatus.Disputed));
            
            if (shouldResolve) {
                vm.prank(admin);
                vdr.resolveDispute(vcId, resolveWithRevoke);
                
                if (resolveWithRevoke) {
                    assertEq(uint256(vdr.getVC(vcId).status), uint256(VDRConstants.VCStatus.Revoked));
                } else {
                    assertEq(uint256(vdr.getVC(vcId).status), uint256(VDRConstants.VCStatus.Active));
                }
            }
        }
    }

    // ============ Duplicate Prevention Tests ============

    /**
     * @dev Fuzz test: duplicate vcId prevention
     */
    function testFuzz_NoDuplicateVcId(bytes32 vcId, address holder2) public {
        vm.assume(vcId != bytes32(0));
        vm.assume(holder2 != address(0));
        
        bytes32 contentHash1 = keccak256("content1");
        bytes32 contentHash2 = keccak256("content2");
        
        // First registration should succeed
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash1, block.timestamp - 1 days);
        
        // Second registration with same vcId should fail
        vm.prank(issuer1);
        vm.expectRevert("VDR: VC already exists");
        vdr.registerVC(vcId, holder2, bytes32(0), contentHash2, block.timestamp - 1 days);
    }

    // ============ Edge Case Tests ============

    /**
     * @dev Fuzz test: very old issuance dates
     */
    function testFuzz_VeryOldIssuanceDate(uint256 daysAgo) public {
        // Filter out extreme values that cause overflow
        vm.assume(daysAgo > 0 && daysAgo <= 36500);
        
        // Warp to far future to allow very old dates
        vm.warp(36500 days);
        
        uint256 issuanceDate = block.timestamp - (daysAgo * 1 days);
        
        // Ensure issuanceDate is valid (> 0 and <= block.timestamp)
        vm.assume(issuanceDate > 0 && issuanceDate <= block.timestamp);
        
        bytes32 vcId = keccak256(abi.encodePacked("old-date", daysAgo));
        bytes32 contentHash = keccak256("content");
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuanceDate, issuanceDate);
        assertTrue(vc.registrationTime >= vc.issuanceDate);
    }

    /**
     * @dev Fuzz test: contentHash uniqueness is not enforced
     * Multiple VCs can have the same contentHash
     */
    function testFuzz_SameContentHash_DifferentVcId(uint8 count) public {
        count = uint8(bound(count, 2, 20));
        
        bytes32 sharedContentHash = keccak256("shared-content");
        
        for (uint8 i = 0; i < count; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("same-content", i));
            
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), sharedContentHash, block.timestamp - 1 days);
        }
        
        // All registrations should succeed
        assertEq(vdr.getTotalVCCount(), count);
    }

    // ============ Gas Efficiency Fuzz Tests ============

    /**
     * @dev Fuzz test: gas usage scales linearly with operations
     * Note: This test verifies that gas usage scales approximately linearly,
     * not a hard cap. First op is more expensive due to storage initialization.
     */
    function testFuzz_GasScaling(uint8 batchSize) public {
        batchSize = uint8(bound(batchSize, 3, 10));
        
        uint256[] memory gasPerOp = new uint256[](batchSize);
        
        for (uint8 i = 0; i < batchSize; i++) {
            bytes32 vcId = keccak256(abi.encodePacked("gas-test", i));
            bytes32 contentHash = keccak256(abi.encodePacked("content", i));
            
            uint256 gasBefore = gasleft();
            vm.prank(issuer1);
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, block.timestamp - 1 days);
            gasPerOp[i] = gasBefore - gasleft();
        }
        
        // After first few ops, gas should stabilize
        // Check that later ops use similar gas (within 50% of each other)
        if (batchSize >= 3) {
            uint256 lastGas = gasPerOp[batchSize - 1];
            uint256 secondLastGas = gasPerOp[batchSize - 2];
            
            // Gas usage for similar operations should be consistent
            uint256 diff = lastGas > secondLastGas ? lastGas - secondLastGas : secondLastGas - lastGas;
            assertTrue(diff < lastGas / 2, "Gas usage not stable");
        }
    }
}
