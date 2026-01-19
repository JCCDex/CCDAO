// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VDR.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/libraries/VDRConstants.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";

contract VDRTest is Test {
    VDR vdrImplementation;
    ERC1967Proxy vdrProxy;
    VDR vdr;
    
    MockERC20 mockERC20;
    MockERC721 mockERC721;
    
    address owner;
    address admin;
    address issuer1;
    address issuer2;
    address verifier;
    address holder1;
    address holder2;

    function setUp() public {
        // Deploy VDR implementation
        vdrImplementation = new VDR();
        
        // Deploy mock tokens
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        
        // Setup addresses
        owner = address(0x1);
        admin = address(0x2);
        issuer1 = address(0x3);
        issuer2 = address(0x4);
        verifier = address(0x5);
        holder1 = address(0x6);
        holder2 = address(0x7);

        // Set block timestamp to a reasonable value to avoid underflow
        vm.warp(100 days);

        // Prepare initialization data
        address[] memory issuers = new address[](2);
        issuers[0] = issuer1;
        issuers[1] = issuer2;

        bytes memory initData = abi.encodeCall(
            VDR.initialize,
            ("Test VDR", owner, issuers)
        );

        // Deploy proxy
        vdrProxy = new ERC1967Proxy(address(vdrImplementation), initData);
        vdr = VDR(address(vdrProxy));

        // Set admin role (owner appoints admin)
        vm.prank(owner);
        vdr.setAdmin(admin);

        // Add verifier role (admin adds verifiers)
        vm.prank(admin);
        vdr.addMember(verifier, VDRConstants.VERIFIER_ROLE);
    }

    // Helper function to set up official tokens for dispute tests
    function _setupOfficialTokens() internal {
        // Set official tokens
        vm.prank(owner);
        vdr.setOfficialERC20(address(mockERC20));
        vm.prank(owner);
        vdr.setOfficialERC721(address(mockERC721));

        // Mint tokens to test accounts for dispute permission
        mockERC20.mint(issuer1, 10000 * 10**18); // 10000 tokens with 18 decimals
        mockERC20.mint(issuer2, 10000 * 10**18);
        mockERC20.mint(holder1, 10000 * 10**18);
        mockERC20.mint(holder2, 10000 * 10**18);
        mockERC20.mint(verifier, 10000 * 10**18);
        
        mockERC721.mint(admin, 1); // Give admin 1 NFT as alternative
    }

    // Helper function to generate unique vcId
    function _getVcId(string memory seed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }

    // Helper function to compute content hash
    function _getContentHash(string memory content) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(content));
    }

    // ============ Initialization Tests ============

    function test_InitializeVDR() public view {
        assertEq(vdr.vdrName(), "Test VDR");
        assertEq(vdr.owner(), owner);
        assertTrue(vdr.isMember(issuer1));
        assertTrue(vdr.hasMemberRole(issuer1, VDRConstants.VERIFIER_ROLE));
    }

    // ============ VC Registration Tests ============

    function test_RegisterVC_IssuerAndHolderDifferent() public {
        bytes32 vcId = _getVcId("test-vc-1");
        bytes32 contentHash = _getContentHash("diploma-content-1");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuer, issuer1);
        assertEq(vc.holder, holder1);
        assertEq(vc.contentHash, contentHash);
        assertEq(vc.issuanceDate, issuanceDate);
        assertEq(vc.registrationTime, block.timestamp);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Active));
    }

    function test_RegisterVC_IssuerIsHolder() public {
        bytes32 vcId = _getVcId("test-vc-2");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, issuer1, contentHash, issuanceDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuer, issuer1);
        assertEq(vc.holder, issuer1);
    }

    function test_RegisterVC_InvalidId() public {
        bytes32 contentHash = _getContentHash("test-content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vm.expectRevert("VDR: invalid VC ID");
        vdr.registerVC(bytes32(0), holder1, contentHash, issuanceDate);
    }

    function test_RegisterVC_InvalidHolder() public {
        bytes32 vcId = _getVcId("test-vc-3");
        bytes32 contentHash = _getContentHash("test-content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vm.expectRevert("VDR: invalid holder");
        vdr.registerVC(vcId, address(0), contentHash, issuanceDate);
    }

    function test_RegisterVC_InvalidContentHash() public {
        bytes32 vcId = _getVcId("test-vc-4");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vm.expectRevert("VDR: invalid content hash");
        vdr.registerVC(vcId, holder1, bytes32(0), issuanceDate);
    }

    function test_RegisterVC_InvalidIssuanceDate_Zero() public {
        bytes32 vcId = _getVcId("test-vc-5");
        bytes32 contentHash = _getContentHash("test-content");
        
        vm.prank(issuer1);
        vm.expectRevert("VDR: invalid issuance date");
        vdr.registerVC(vcId, holder1, contentHash, 0);
    }

    function test_RegisterVC_InvalidIssuanceDate_Future() public {
        bytes32 vcId = _getVcId("test-vc-6");
        bytes32 contentHash = _getContentHash("test-content");
        uint256 futureDate = block.timestamp + 1 days;
        
        vm.prank(issuer1);
        vm.expectRevert("VDR: invalid issuance date");
        vdr.registerVC(vcId, holder1, contentHash, futureDate);
    }

    function test_RegisterVC_Duplicate() public {
        bytes32 vcId = _getVcId("test-vc-7");
        bytes32 contentHash1 = _getContentHash("content-1");
        bytes32 contentHash2 = _getContentHash("content-2");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Register first VC
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash1, issuanceDate);
        
        // Try to register with same vcId - should fail
        vm.prank(issuer2);
        vm.expectRevert("VDR: VC already exists");
        vdr.registerVC(vcId, holder2, contentHash2, issuanceDate);
    }

    function test_RegisterVC_AnyoneCanRegisterAsIssuer() public {
        bytes32 vcId = _getVcId("test-vc-8");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        address randomAddr = address(0x77);
        
        vm.prank(randomAddr);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuer, randomAddr);
        assertEq(vc.holder, holder1);
    }

    function test_RegisterVC_IssuanceDatePast() public {
        bytes32 vcId = _getVcId("test-vc-9");
        bytes32 contentHash = _getContentHash("content");
        // Use a past date that is still valid (1 day ago)
        uint256 pastDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, pastDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuanceDate, pastDate);
        assertTrue(vc.registrationTime >= vc.issuanceDate);
    }

    function test_RegisterVC_IssuanceDateEquals_CurrentTimestamp() public {
        bytes32 vcId = _getVcId("test-vc-boundary");
        bytes32 contentHash = _getContentHash("content");
        // Edge case: issuanceDate == block.timestamp (should be allowed)
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, block.timestamp);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuanceDate, block.timestamp);
        assertEq(vc.registrationTime, block.timestamp);
    }

    function test_RegisterVC_EventEmitted() public {
        bytes32 vcId = _getVcId("test-vc-event");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;

        vm.prank(issuer1);
        vm.expectEmit(true, true, false, false);
        emit IVDR.VCRegistered(vcId, issuer1, holder1, bytes32(0));
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);
    }

    function test_RegisterVC_IndexingIssuer() public {
        bytes32 vcId1 = _getVcId("test-vc-idx1");
        bytes32 vcId2 = _getVcId("test-vc-idx2");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Same issuer registers two VCs
        vm.prank(issuer1);
        vdr.registerVC(vcId1, holder1, contentHash, issuanceDate);
        
        vm.prank(issuer1);
        vdr.registerVC(vcId2, holder2, contentHash, issuanceDate);

        // Verify both VCs are indexed under issuer1
        bytes32[] memory issuerVCs = vdr.getIssuerVCs(issuer1);
        assertEq(issuerVCs.length, 2);
        assertEq(issuerVCs[0], vcId1);
        assertEq(issuerVCs[1], vcId2);
    }

    function test_RegisterVC_IndexingHolder() public {
        bytes32 vcId1 = _getVcId("test-vc-idx3");
        bytes32 vcId2 = _getVcId("test-vc-idx4");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Different issuers register VCs for the same holder
        vm.prank(issuer1);
        vdr.registerVC(vcId1, holder1, contentHash, issuanceDate);
        
        vm.prank(issuer2);
        vdr.registerVC(vcId2, holder1, contentHash, issuanceDate);

        // Verify both VCs are indexed under holder1
        bytes32[] memory holderVCs = vdr.getHolderVCs(holder1);
        assertEq(holderVCs.length, 2);
        assertEq(holderVCs[0], vcId1);
        assertEq(holderVCs[1], vcId2);
    }

    function test_RegisterVC_StatusInitialActive() public {
        bytes32 vcId = _getVcId("test-vc-status");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        // Verify initial status is Active
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Active));
    }

    // ============ VC Query Tests ============

    function test_GetVC() public {
        bytes32 vcId = _getVcId("test-vc-10");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 2 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.vcId, vcId);
        assertEq(vc.issuer, issuer1);
        assertEq(vc.holder, holder1);
    }

    // ============ VC Indexing Tests ============

    function test_GetIssuerVCs() public {
        bytes32 vcId1 = _getVcId("test-vc-13");
        bytes32 vcId2 = _getVcId("test-vc-14");
        bytes32 vcId3 = _getVcId("test-vc-15");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId1, holder1, contentHash, issuanceDate);
        
        vm.prank(issuer1);
        vdr.registerVC(vcId2, holder2, contentHash, issuanceDate);
        
        vm.prank(issuer2);
        vdr.registerVC(vcId3, holder1, contentHash, issuanceDate);

        bytes32[] memory issuer1VCs = vdr.getIssuerVCs(issuer1);
        assertEq(issuer1VCs.length, 2);
        
        bytes32[] memory issuer2VCs = vdr.getIssuerVCs(issuer2);
        assertEq(issuer2VCs.length, 1);
    }

    function test_GetHolderVCs() public {
        bytes32 vcId1 = _getVcId("test-vc-16");
        bytes32 vcId2 = _getVcId("test-vc-17");
        bytes32 vcId3 = _getVcId("test-vc-18");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId1, holder1, contentHash, issuanceDate);
        
        vm.prank(issuer1);
        vdr.registerVC(vcId2, holder1, contentHash, issuanceDate);
        
        vm.prank(issuer2);
        vdr.registerVC(vcId3, holder2, contentHash, issuanceDate);

        bytes32[] memory holder1VCs = vdr.getHolderVCs(holder1);
        assertEq(holder1VCs.length, 2);
        
        bytes32[] memory holder2VCs = vdr.getHolderVCs(holder2);
        assertEq(holder2VCs.length, 1);
    }

    // ============ VC Revocation Tests ============

    function test_RevokeVC() public {
        bytes32 vcId = _getVcId("test-vc-19");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(issuer1);
        vdr.revokeVC(vcId);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Revoked));
    }

    function test_RevokeVC_OnlyIssuerOrOwner() public {
        bytes32 vcId = _getVcId("test-vc-20");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(holder1); // Not issuer
        vm.expectRevert("VDR: only issuer can revoke");
        vdr.revokeVC(vcId);
    }

    function test_RevokeVC_OwnerCanRevoke() public {
        bytes32 vcId = _getVcId("test-vc-21");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(owner);
        vdr.revokeVC(vcId);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Revoked));
    }

    // ============ VC Dispute Tests ============

    function test_DisputeVC() public {
        _setupOfficialTokens();
        
        bytes32 vcId = _getVcId("test-vc-22");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(holder1);
        vdr.disputeVC(vcId);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Disputed));
    }

    function test_DisputeVC_InsufficientTokens() public {
        // Note: _setupOfficialTokens is NOT called, so accounts have 0 tokens
        bytes32 vcId = _getVcId("test-vc-insufficient");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        // holder1 has no tokens, should fail
        vm.prank(holder1);
        vm.expectRevert("VDR: insufficient official token balance to dispute");
        vdr.disputeVC(vcId);
    }

    function test_DisputeVC_OwnerBypass() public {
        // Note: _setupOfficialTokens is NOT called, so accounts have 0 tokens
        bytes32 vcId = _getVcId("test-vc-owner-bypass");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        // Owner can dispute even without tokens
        vm.prank(owner);
        vdr.disputeVC(vcId);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Disputed));
    }

    function test_DisputeVC_WithERC721() public {
        // Setup only ERC721
        vm.prank(owner);
        vdr.setOfficialERC721(address(mockERC721));
        
        // Give holder1 one NFT
        mockERC721.mint(holder1, 1);
        
        bytes32 vcId = _getVcId("test-vc-erc721");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        // Should succeed with 1 NFT
        vm.prank(holder1);
        vdr.disputeVC(vcId);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Disputed));
    }

    function test_ResolveDispute_Revoke() public {
        _setupOfficialTokens();
        
        bytes32 vcId = _getVcId("test-vc-24");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(holder1);
        vdr.disputeVC(vcId);
        
        vm.prank(admin);
        vdr.resolveDispute(vcId, true);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Revoked));
    }

    function test_ResolveDispute_Restore() public {
        _setupOfficialTokens();
        
        bytes32 vcId = _getVcId("test-vc-24");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        vm.prank(holder1);
        vdr.disputeVC(vcId);

        vm.prank(admin);
        vdr.resolveDispute(vcId, false);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Active));
    }

    function test_GetDisputedVCs() public {
        _setupOfficialTokens();
        
        bytes32 vc1 = _getVcId("test-vc-disputed-1");
        bytes32 vc2 = _getVcId("test-vc-disputed-2");
        bytes32 vc3 = _getVcId("test-vc-disputed-3");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Register three VCs
        vm.prank(issuer1);
        vdr.registerVC(vc1, holder1, contentHash, issuanceDate);
        vm.prank(issuer1);
        vdr.registerVC(vc2, holder1, contentHash, issuanceDate);
        vm.prank(issuer1);
        vdr.registerVC(vc3, holder1, contentHash, issuanceDate);

        // Dispute two of them
        vm.prank(holder1);
        vdr.disputeVC(vc1);
        vm.prank(holder1);
        vdr.disputeVC(vc2);

        // Check disputed VCs
        bytes32[] memory disputed = vdr.getDisputedVCs();
        assertEq(disputed.length, 2);
        // Both vc1 and vc2 should be in the array
        assertEq(disputed[0], vc1);
        assertEq(disputed[1], vc2);
    }

    function test_GetDisputedVCs_AfterResolve() public {
        _setupOfficialTokens();
        
        bytes32 vc1 = _getVcId("test-vc-disputed-4");
        bytes32 vc2 = _getVcId("test-vc-disputed-5");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Register and dispute two VCs
        vm.prank(issuer1);
        vdr.registerVC(vc1, holder1, contentHash, issuanceDate);
        vm.prank(issuer1);
        vdr.registerVC(vc2, holder1, contentHash, issuanceDate);
        
        vm.prank(holder1);
        vdr.disputeVC(vc1);
        vm.prank(holder1);
        vdr.disputeVC(vc2);

        // Resolve one dispute
        vm.prank(admin);
        vdr.resolveDispute(vc1, true);

        // Check that only vc2 remains in disputed list
        bytes32[] memory disputed = vdr.getDisputedVCs();
        assertEq(disputed.length, 1);
        assertEq(disputed[0], vc2);
    }

    function test_GetTotalVCCount() public {
        bytes32 vc1 = _getVcId("test-vc-count-1");
        bytes32 vc2 = _getVcId("test-vc-count-2");
        bytes32 vc3 = _getVcId("test-vc-count-3");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Initially 0 VCs
        assertEq(vdr.getTotalVCCount(), 0);
        
        // Register first VC
        vm.prank(issuer1);
        vdr.registerVC(vc1, holder1, contentHash, issuanceDate);
        assertEq(vdr.getTotalVCCount(), 1);
        
        // Register second VC
        vm.prank(issuer1);
        vdr.registerVC(vc2, holder1, contentHash, issuanceDate);
        assertEq(vdr.getTotalVCCount(), 2);
        
        // Register third VC
        vm.prank(issuer1);
        vdr.registerVC(vc3, holder1, contentHash, issuanceDate);
        assertEq(vdr.getTotalVCCount(), 3);
    }

    function test_GetTotalVCCount_AfterRevoke() public {
        bytes32 vc1 = _getVcId("test-vc-count-4");
        bytes32 vc2 = _getVcId("test-vc-count-5");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // Register two VCs
        vm.prank(issuer1);
        vdr.registerVC(vc1, holder1, contentHash, issuanceDate);
        vm.prank(issuer1);
        vdr.registerVC(vc2, holder1, contentHash, issuanceDate);
        
        assertEq(vdr.getTotalVCCount(), 2);
        
        // Revoke one VC
        vm.prank(issuer1);
        vdr.revokeVC(vc1);
        
        // Count should be decremented
        assertEq(vdr.getTotalVCCount(), 1);
    }

    // ============ Verification Tests ============

    // ============ Member Management Tests ============

    function test_AddMember() public {
        address newMember = address(0x77);

        vm.prank(admin);
        vdr.addMember(newMember, VDRConstants.VERIFIER_ROLE);

        assertTrue(vdr.isMember(newMember));
        assertTrue(vdr.hasMemberRole(newMember, VDRConstants.VERIFIER_ROLE));
    }

    function test_RemoveMember() public {
        address memberToRemove = address(0x88);

        vm.prank(admin);
        vdr.addMember(memberToRemove, VDRConstants.VERIFIER_ROLE);

        assertTrue(vdr.isMember(memberToRemove));

        vm.prank(admin);
        vdr.removeMember(memberToRemove);

        assertFalse(vdr.isMember(memberToRemove));
    }

    function test_GetMemberCount() public view {
        // admin, issuer1, issuer2, verifier = 4 members
        assertEq(vdr.getMemberCount(), 4);
    }

    function test_GetMembers() public view {
        address[] memory members = vdr.getMembers();
        assertEq(members.length, 4);
    }

    function test_GetMember() public view {
        VDRConstants.Member memory member = vdr.getMember(issuer1);
        assertEq(member.memberAddress, issuer1);
        assertEq(member.role, VDRConstants.VERIFIER_ROLE);
        assertGt(member.joinedTime, 0);
    }

    // ============ Version Tests ============

    function test_GetVersion() public view {
        (uint256 major, uint256 minor, uint256 patch) = vdr.getVersion();
        assertEq(major, 1);
        assertEq(minor, 0);
        assertEq(patch, 0);
    }

    function test_GetImplementation() public view {
        assertNotEq(vdr.getImplementation(), address(0));
    }

    // ============ Time Tests ============

    function test_RegistrationTime_GreaterThanOrEqualIssuanceTime() public {
        bytes32 vcId = _getVcId("test-vc-29");
        bytes32 contentHash = _getContentHash("content");
        uint256 pastIssuanceDate = block.timestamp - 10 days;
        
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, pastIssuanceDate);

        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertTrue(vc.registrationTime >= vc.issuanceDate);
    }

    // ============ Integration Tests ============

    function test_CompleteVCLifecycle() public {
        _setupOfficialTokens();
        
        bytes32 vcId = _getVcId("test-vc-lifecycle");
        bytes32 contentHash = _getContentHash("diploma-content");
        uint256 issuanceDate = block.timestamp - 5 days;
        
        // 1. issuer1 registers credential for holder1
        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, contentHash, issuanceDate);

        // 2. Holder disputes
        vm.prank(holder1);
        vdr.disputeVC(vcId);

        // 3. Admin resolves dispute
        vm.prank(admin);
        vdr.resolveDispute(vcId, false);

        VDRConstants.VCRecord memory restored = vdr.getVC(vcId);
        assertEq(uint256(restored.status), uint256(VDRConstants.VCStatus.Active));

        // 4. Issuer revokes
        vm.prank(issuer1);
        vdr.revokeVC(vcId);

        VDRConstants.VCRecord memory revoked = vdr.getVC(vcId);
        assertEq(uint256(revoked.status), uint256(VDRConstants.VCStatus.Revoked));
    }

    function test_MultipleIssuersMultipleHolders() public {
        bytes32 vc1 = _getVcId("test-vc-multi-1");
        bytes32 vc2 = _getVcId("test-vc-multi-2");
        bytes32 vc3 = _getVcId("test-vc-multi-3");
        bytes32 contentHash = _getContentHash("content");
        uint256 issuanceDate = block.timestamp - 1 days;
        
        // issuer1 issues VC to holder1
        vm.prank(issuer1);
        vdr.registerVC(vc1, holder1, contentHash, issuanceDate);
        
        // issuer1 issues VC to holder2
        vm.prank(issuer1);
        vdr.registerVC(vc2, holder2, contentHash, issuanceDate);

        // issuer2 issues VC to holder1
        vm.prank(issuer2);
        vdr.registerVC(vc3, holder1, contentHash, issuanceDate);

        // Verify issuer indices
        bytes32[] memory issuer1VCs = vdr.getIssuerVCs(issuer1);
        assertEq(issuer1VCs.length, 2);

        bytes32[] memory issuer2VCs = vdr.getIssuerVCs(issuer2);
        assertEq(issuer2VCs.length, 1);

        // Verify holder indices
        bytes32[] memory holder1VCs = vdr.getHolderVCs(holder1);
        assertEq(holder1VCs.length, 2);

        bytes32[] memory holder2VCs = vdr.getHolderVCs(holder2);
        assertEq(holder2VCs.length, 1);
    }

    // ============ Official DAO Assets Tests ============

    function test_SetOfficialERC20() public {
        address mockERC20 = address(0xAAAA);
        
        // Owner can set official ERC20
        vm.prank(owner);
        vdr.setOfficialERC20(mockERC20);
        
        // Verify it was set
        assertEq(vdr.getOfficialERC20(), mockERC20);
    }

    function test_SetOfficialERC20_OnlyOwner() public {
        address mockERC20 = address(0xBBBB);
        
        // Non-owner cannot set official ERC20
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", admin)
        );
        vdr.setOfficialERC20(mockERC20);
    }

    function test_SetOfficialERC20_RejectZeroAddress() public {
        // Cannot set zero address
        vm.prank(owner);
        vm.expectRevert("VDR: invalid ERC20 address");
        vdr.setOfficialERC20(address(0));
    }

    function test_SetOfficialERC721() public {
        address mockERC721 = address(0xCCCC);
        
        // Owner can set official ERC721
        vm.prank(owner);
        vdr.setOfficialERC721(mockERC721);
        
        // Verify it was set
        assertEq(vdr.getOfficialERC721(), mockERC721);
    }

    function test_SetOfficialERC721_OnlyOwner() public {
        address mockERC721 = address(0xDDDD);
        
        // Non-owner cannot set official ERC721
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", admin)
        );
        vdr.setOfficialERC721(mockERC721);
    }

    function test_SetOfficialERC721_RejectZeroAddress() public {
        // Cannot set zero address
        vm.prank(owner);
        vm.expectRevert("VDR: invalid ERC721 address");
        vdr.setOfficialERC721(address(0));
    }

    function test_OfficialTokensInitiallyZero() public {
        // Official tokens should be zero addresses initially
        assertEq(vdr.getOfficialERC20(), address(0));
        assertEq(vdr.getOfficialERC721(), address(0));
    }

    function test_SetBothOfficialTokens() public {
        address mockERC20 = address(0xEEEE);
        address mockERC721 = address(0xFFFF);
        
        // Owner can set both
        vm.prank(owner);
        vdr.setOfficialERC20(mockERC20);
        
        vm.prank(owner);
        vdr.setOfficialERC721(mockERC721);
        
        // Both should be set
        assertEq(vdr.getOfficialERC20(), mockERC20);
        assertEq(vdr.getOfficialERC721(), mockERC721);
    }

    function test_UpdateOfficialTokens() public {
        address mockERC20_v1 = address(0x1111);
        address mockERC20_v2 = address(0x2222);
        address mockERC721 = address(0x3333);
        
        // Set initial versions
        vm.prank(owner);
        vdr.setOfficialERC20(mockERC20_v1);
        
        vm.prank(owner);
        vdr.setOfficialERC721(mockERC721);
        
        // Update ERC20
        vm.prank(owner);
        vdr.setOfficialERC20(mockERC20_v2);
        
        // Verify update
        assertEq(vdr.getOfficialERC20(), mockERC20_v2);
        assertEq(vdr.getOfficialERC721(), mockERC721);
    }
}
