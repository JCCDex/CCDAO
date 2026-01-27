// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VDR.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/libraries/VDRConstants.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";

/**
 * @title VDR Gas Benchmark Test
 * @dev Measures gas consumption for key VDR operations
 * 
 * Usage:
 * 1. Run with optimizer_runs=10000:
 *    forge test --match-contract VDRGasBenchmark -v
 * 
 * 2. Change optimizer_runs in foundry.toml to 100000
 * 3. Run again and compare gas values
 * 
 * This helps determine if higher optimizer runs reduce execution gas enough
 * to offset increased deployment costs
 */
contract VDRGasBenchmark is Test {
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
    address holder3;

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
        holder3 = address(0x8);

        // Set block timestamp
        vm.warp(100 days);

        // Prepare initialization data
        address[] memory verifiers = new address[](2);
        verifiers[0] = issuer1;
        verifiers[1] = issuer2;

        bytes memory initData = abi.encodeCall(
            VDR.initialize,
            ("Test VDR", owner, verifiers)
        );

        // Deploy proxy
        vdrProxy = new ERC1967Proxy(address(vdrImplementation), initData);
        vdr = VDR(address(vdrProxy));

        // Set admin role
        vm.prank(owner);
        vdr.setAdmin(admin);

        // Add verifier role
        vm.prank(admin);
        vdr.addMember(verifier, VDRConstants.VERIFIER_ROLE);
    }

    function _getVcId(string memory seed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }

    function _getContentHash(string memory content) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(content));
    }

    // ============ Gas Benchmark Tests ============

    /**
     * @dev Benchmark: Register single VC
     * Core operation: Storage write + event emit
     */
    function test_GasBenchmark_RegisterVC_Single() public {
        bytes32 vcId = _getVcId("benchmark-vc-1");
        bytes32 contentHash = _getContentHash("content-1");
        uint256 issuanceDate = block.timestamp - 1 days;

        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        // Check registration success
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(vc.issuer, issuer1);
    }

    /**
     * @dev Benchmark: Register multiple VCs in sequence
     * Measures: Repeated storage operations
     */
    function test_GasBenchmark_RegisterVC_Batch10() public {
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 10; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("batch-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(11 - i) * 1 days;

            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();
    }

    /**
     * @dev Benchmark: Revoke single VC
     * Core operation: State change from Active to Revoked
     */
    function test_GasBenchmark_RevokeVC_Single() public {
        // First register a VC
        bytes32 vcId = _getVcId("revoke-benchmark-vc-1");
        bytes32 contentHash = _getContentHash("revoke-content-1");
        uint256 issuanceDate = block.timestamp - 1 days;

        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);

        // Then revoke it
        vm.prank(issuer1);
        vdr.revokeVC(vcId);

        // Verify revocation
        VDRConstants.VCRecord memory vc = vdr.getVC(vcId);
        assertEq(uint256(vc.status), uint256(VDRConstants.VCStatus.Revoked));
    }

    /**
     * @dev Benchmark: Revoke multiple VCs in sequence
     * Measures: Repeated state changes
     */
    function test_GasBenchmark_RevokeVC_Batch10() public {
        // Register 10 VCs first
        bytes32[] memory vcIds = new bytes32[](10);
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 10; i++) {
            vcIds[i] = _getVcId(string(abi.encodePacked("revoke-batch-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("revoke-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(11 - i) * 1 days;

            vdr.registerVC(vcIds[i], holder1, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        // Now revoke all of them
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 10; i++) {
            vdr.revokeVC(vcIds[i]);
        }
        vm.stopPrank();
    }

    /**
     * @dev Benchmark: Query VCs by issuer (read-only)
     * Measures: Array iteration + filtering
     */
    function test_GasBenchmark_QueryByIssuer() public {
        // Register VCs from issuer1
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 5; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("issuer-query-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("issuer-query-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(6 - i) * 1 days;

            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        // Query them back (repeated calls)
        for (uint256 i = 0; i < 5; i++) {
            vdr.getIssuerVCs(issuer1);
        }
    }

    /**
     * @dev Benchmark: Query VCs by holder (read-only)
     * Measures: Array iteration + filtering
     */
    function test_GasBenchmark_QueryByHolder() public {
        // Register VCs to holder1
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 5; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("holder-query-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("holder-query-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(6 - i) * 1 days;

            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        // Query them back (repeated calls)
        for (uint256 i = 0; i < 5; i++) {
            vdr.getHolderVCs(holder1);
        }
    }

    /**
     * @dev Benchmark: Mixed operations (realistic workload)
     * Measures: Combination of register, revoke, and query operations
     */
    function test_GasBenchmark_MixedOperations() public {
        // Register initial batch
        vm.startPrank(issuer1);
        bytes32[] memory vcIds = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            vcIds[i] = _getVcId(string(abi.encodePacked("mixed-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("mixed-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(6 - i) * 1 days;

            vdr.registerVC(vcIds[i], holder1, bytes32(0), contentHash, issuanceDate);
        }

        // Query by issuer
        vdr.getIssuerVCs(issuer1);

        // Revoke one
        vdr.revokeVC(vcIds[0]);

        // Register more
        for (uint256 i = 5; i < 8; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("mixed-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("mixed-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(9 - i) * 1 days;

            vdr.registerVC(vcId, holder2, bytes32(0), contentHash, issuanceDate);
        }

        // Query by holder
        vdr.getHolderVCs(holder1);
        vdr.getHolderVCs(holder2);

        // Revoke batch
        for (uint256 i = 1; i < 3; i++) {
            vdr.revokeVC(vcIds[i]);
        }
        vm.stopPrank();
    }

    /**
     * @dev Benchmark: Stress test with many VCs
     * Measures: Behavior with growing storage
     */
    function test_GasBenchmark_StressTest_Register20() public {
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 20; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("stress-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("stress-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(21 - i) * 1 days;

            address currentHolder = i % 2 == 0 ? holder1 : holder2;
            vdr.registerVC(vcId, currentHolder, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        // Query accumulated data
        vdr.getIssuerVCs(issuer1);
        vdr.getHolderVCs(holder1);
        vdr.getHolderVCs(holder2);
    }

    /**
     * @dev Benchmark: Get single VC (read-only)
     * Measures: Direct storage lookup
     */
    function test_GasBenchmark_GetVC_Single() public {
        // Register a VC first
        bytes32 vcId = _getVcId("get-benchmark-vc-1");
        bytes32 contentHash = _getContentHash("get-content-1");
        uint256 issuanceDate = block.timestamp - 1 days;

        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);

        // Retrieve it multiple times
        for (uint256 i = 0; i < 10; i++) {
            vdr.getVC(vcId);
        }
    }

    /**
     * @dev Heavy stress test: 5000 register operations
     * This simulates real-world usage where the contract is called thousands of times
     * Measures cumulative cost difference between optimizer runs
     */
    function test_GasBenchmark_HeavyStress_Register5000() public {
        vm.startPrank(issuer1);
        
        // Register 5000 VCs
        // Split into multiple holders to avoid array getting too large for one holder
        for (uint256 i = 0; i < 5000; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("heavy-stress-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("heavy-stress-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(5001 - i) * 1 seconds;
            
            // Distribute across multiple holders (round-robin)
            address currentHolder = (i % 3 == 0) ? holder1 : (i % 3 == 1) ? holder2 : holder3;
            
            vdr.registerVC(vcId, currentHolder, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();
    }

    /**
     * @dev Heavy stress test: 5000 read operations
     * Simulates continuous queries on accumulated data
     */
    function test_GasBenchmark_HeavyStress_Query5000() public {
        // First register enough data
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < 100; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("query-stress-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("query-stress-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(101 - i) * 1 seconds;
            
            address currentHolder = (i % 3 == 0) ? holder1 : (i % 3 == 1) ? holder2 : holder3;
            vdr.registerVC(vcId, currentHolder, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        // Now do 5000 query operations
        vm.startPrank(verifier);
        for (uint256 i = 0; i < 5000; i++) {
            // Query different holders in round-robin
            if (i % 3 == 0) {
                vdr.getHolderVCs(holder1);
            } else if (i % 3 == 1) {
                vdr.getHolderVCs(holder2);
            } else {
                vdr.getHolderVCs(holder3);
            }
        }
        vm.stopPrank();
    }

    /**
     * @dev Heavy stress test: 5000 get operations on single VC
     * Simulates repeated lookups of same credential
     */
    function test_GasBenchmark_HeavyStress_GetSingle5000() public {
        // Register one VC
        bytes32 vcId = _getVcId("single-stress-vc");
        bytes32 contentHash = _getContentHash("single-stress-content");
        uint256 issuanceDate = block.timestamp - 1 days;

        vm.prank(issuer1);
        vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);

        // Retrieve it 5000 times
        vm.startPrank(verifier);
        for (uint256 i = 0; i < 5000; i++) {
            vdr.getVC(vcId);
        }
        vm.stopPrank();
    }

    /**
     * @dev Heavy stress test: Mixed intensive operations
     * 1000 registers + 1000 revokes + 1000 queries + 1000 direct gets
     */
    function test_GasBenchmark_HeavyStress_MixedIntensive() public {
        uint256 iterations = 100;  // Reduced from 1000 to avoid memory overflow
        bytes32[] memory vcIds = new bytes32[](iterations);
        
        // Phase 1: 100 registers
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < iterations; i++) {
            vcIds[i] = _getVcId(string(abi.encodePacked("mixed-intensive-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("mixed-intensive-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(iterations - i) * 1 seconds;
            
            address currentHolder = (i % 2 == 0) ? holder1 : holder2;
            vdr.registerVC(vcIds[i], currentHolder, bytes32(0), contentHash, issuanceDate);
        }

        // Phase 2: 100 revokes
        for (uint256 i = 0; i < iterations; i++) {
            vdr.revokeVC(vcIds[i]);
        }
        vm.stopPrank();

        // Phase 3: 100 queries by issuer
        vm.startPrank(verifier);
        for (uint256 i = 0; i < iterations; i++) {
            vdr.getIssuerVCs(issuer1);
        }

        // Phase 4: 100 direct get operations
        // Re-register some to have active VCs
        vm.stopPrank();
        vm.startPrank(issuer1);
        for (uint256 i = 0; i < iterations; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("mixed-intensive-new-vc-", vm.toString(i))));
            bytes32 contentHash = _getContentHash(string(abi.encodePacked("mixed-intensive-new-content-", vm.toString(i))));
            uint256 issuanceDate = block.timestamp - uint256(iterations - i) * 1 seconds;
            
            vdr.registerVC(vcId, holder1, bytes32(0), contentHash, issuanceDate);
        }
        vm.stopPrank();

        vm.startPrank(verifier);
        for (uint256 i = 0; i < iterations; i++) {
            bytes32 vcId = _getVcId(string(abi.encodePacked("mixed-intensive-new-vc-", vm.toString(i))));
            vdr.getVC(vcId);
        }
        vm.stopPrank();
    }
}
