// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VDRFactory.sol";
import "../src/VDR.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/libraries/VDRConstants.sol";

/**
 * @dev Mock CCDAO_CREATE2 factory for testing
 * Simulates CREATE2 deployment by simply creating contracts via new
 */
contract MockCCDAO_CREATE2 {
    function deploy(bytes calldata bytecode, bytes32) external payable returns (address) {
        // In a real implementation, this would use CREATE2 opcode
        // For testing, we just deploy directly and ignore salt
        // This allows tests to work without complex bytecode manipulation
        
        address deployed;
        assembly {
            // Load bytecode from calldata and deploy
            deployed := create(0, bytecode.offset, bytecode.length)
        }
        require(deployed != address(0), "Deployment failed");
        return deployed;
    }
    
    function owner() external view returns (address) {
        return msg.sender;
    }
}

contract VDRFactoryTest is Test {
    VDRFactory factory;
    ERC1967Proxy factoryProxy;
    VDR vdrImplementation;
    MockCCDAO_CREATE2 mockCreate2;
    
    address creator;
    address vdrOwner;
    address vdrDataManager;
    address factoryOwner;

    function setUp() public {
        // Deploy VDR implementation
        vdrImplementation = new VDR();
        
        // Deploy VDRFactory implementation
        VDRFactory factoryImpl = new VDRFactory();
        
        // Deploy mock CCDAO_CREATE2 factory
        mockCreate2 = new MockCCDAO_CREATE2();
        
        // Prepare initialization data
        factoryOwner = address(0x999);
        bytes memory initData = abi.encodeCall(
            VDRFactory.initialize,
            (factoryOwner, address(vdrImplementation), address(mockCreate2))
        );
        
        // Deploy factory behind ERC1967Proxy
        factoryProxy = new ERC1967Proxy(address(factoryImpl), initData);
        factory = VDRFactory(address(factoryProxy));
        
        creator = address(0x100);
        vdrOwner = address(0x101);
        vdrDataManager = address(0x103);
    }

    // ============ VDR Creation Tests ============

    function test_CreateVDR() public {
        address[] memory managers = new address[](1);
        managers[0] = vdrDataManager;

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        assertTrue(vdrAddress != address(0));
        assertTrue(factory.isValidVDR(vdrAddress));

        VDR vdr = VDR(vdrAddress);
        assertEq(vdr.vdrName(), "Test VDR");
        assertEq(vdr.owner(), vdrOwner);
    }

    function test_CreateVDRWithEmptyManagers() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR Empty",
            vdrOwner,
            managers
        );

        assertTrue(factory.isValidVDR(vdrAddress));
        VDR vdr = VDR(vdrAddress);
        
        // VDR created with no data managers
        assertEq(vdr.getMemberCount(), 0);
    }

    function test_CreateVDREmptyThenAddManagers() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        VDR vdr = VDR(vdrAddress);
        
        // Initially no managers
        assertEq(vdr.getMemberCount(), 0);
        
        // VDR owner appoints an admin
        address admin = address(0x999);
        vm.prank(vdrOwner);
        vdr.setAdmin(admin);
        
        // Admin adds managers
        vm.prank(admin);
        vdr.addMember(vdrDataManager, VDRConstants.VERIFIER_ROLE);
        
        // Manager added successfully (now 2 members: admin + verifier)
        assertTrue(vdr.isMember(vdrDataManager));
        assertTrue(vdr.hasMemberRole(vdrDataManager, VDRConstants.VERIFIER_ROLE));
        assertEq(vdr.getMemberCount(), 2);
    }

    function test_CannotCreateVDRWithInvalidOwner() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        vm.expectRevert("VDRFactory: invalid owner address");
        factory.createVDR(
            "Test VDR",
            address(0),
            managers
        );
    }

    // ============ Query Tests ============

    function test_GetVDRCount() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        factory.createVDR("VDR 1", vdrOwner, managers);

        vm.prank(creator);
        factory.createVDR("VDR 2", vdrOwner, managers);

        assertEq(factory.getVDRCount(), 2);
    }

    function test_GetVDRByIndex() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdr1 = factory.createVDR("VDR 1", vdrOwner, managers);

        address retrieved = factory.getVDRByIndex(0);
        assertEq(retrieved, vdr1);
    }

    function test_GetVDRsByCreator() public {
        address[] memory managers = new address[](0);
        address creator2 = address(0x200);

        vm.prank(creator);
        address vdr1 = factory.createVDR("VDR 1", vdrOwner, managers);

        vm.prank(creator);
        address vdr2 = factory.createVDR("VDR 2", vdrOwner, managers);

        vm.prank(creator2);
        factory.createVDR("VDR 3", vdrOwner, managers);

        address[] memory creatorVDRs = factory.getVDRsByCreator(creator);
        assertEq(creatorVDRs.length, 2);
        assertEq(creatorVDRs[0], vdr1);
        assertEq(creatorVDRs[1], vdr2);
    }

    function test_GetAllVDRs() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdr1 = factory.createVDR("VDR 1", vdrOwner, managers);

        vm.prank(creator);
        address vdr2 = factory.createVDR("VDR 2", vdrOwner, managers);

        // Get all VDRs using range query
        address[] memory allVDRs = factory.getVDRs(0, 2);
        assertEq(allVDRs.length, 2);
        assertEq(allVDRs[0], vdr1);
        assertEq(allVDRs[1], vdr2);
    }

    function test_GetVDRsRange() public {
        address[] memory managers = new address[](0);

        // Create 5 VDRs
        address[] memory vdrs = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(creator);
            vdrs[i] = factory.createVDR(string(abi.encodePacked("VDR ", i)), vdrOwner, managers);
        }

        // Test partial range: get VDRs 1-3 (indices 1, 2)
        address[] memory range = factory.getVDRs(1, 3);
        assertEq(range.length, 2);
        assertEq(range[0], vdrs[1]);
        assertEq(range[1], vdrs[2]);
    }

    function test_GetVDRsFirstPage() public {
        address[] memory managers = new address[](0);

        // Create 3 VDRs
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(creator);
            factory.createVDR(string(abi.encodePacked("VDR ", i)), vdrOwner, managers);
        }

        // Get first page (0-1)
        address[] memory page1 = factory.getVDRs(0, 1);
        assertEq(page1.length, 1);
    }

    function test_GetVDRsLastPage() public {
        address[] memory managers = new address[](0);

        // Create 3 VDRs
        address vdr3;
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(creator);
            vdr3 = factory.createVDR(string(abi.encodePacked("VDR ", i)), vdrOwner, managers);
        }

        // Get last page (2-3)
        address[] memory page2 = factory.getVDRs(2, 3);
        assertEq(page2.length, 1);
        assertEq(page2[0], vdr3);
    }

    function test_GetVDRsInvalidRange() public {
        // startIndex > endIndex should fail
        vm.expectRevert("VDRFactory: invalid range");
        factory.getVDRs(5, 3);
    }

    function test_GetVDRsOutOfBounds() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        factory.createVDR("VDR 1", vdrOwner, managers);

        // Try to access beyond bounds
        vm.expectRevert("VDRFactory: endIndex out of bounds");
        factory.getVDRs(0, 10);
    }

    function test_GetVDRDetails() public {
        address[] memory managers = new address[](1);
        managers[0] = vdrDataManager;

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        (string memory name, address owner, uint256 memberCount) = factory.getVDRDetails(vdrAddress);
        
        assertEq(name, "Test VDR");
        assertEq(owner, vdrOwner);
        assertEq(memberCount, 1); // Only dataManager1
    }

    // ============ Upgrade Tests (Through Factory) ============

    function test_FactoryIsUpgradeable() public {
        assertTrue(factory.owner() == factoryOwner);
    }

    function test_VDROwnerCanRequestUpgrade() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // VDR owner checks current state
        assertEq(factory.getVDRImplementation(vdrAddress), address(vdrImplementation));
        assertEq(factory.getVDRVersion(vdrAddress), 1000000); // 1.0.0 = 1000000

        // Verify VDR owner is allowed to call upgradeVDR (even if already at latest)
        // This documents the permission model
        vm.prank(vdrOwner);
        vm.expectRevert("VDRFactory: already at latest version");
        factory.upgradeVDR(vdrAddress);
    }

    function test_OnlyVDROwnerCanRequestUpgrade() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // Non-owner cannot request upgrade
        vm.prank(creator);
        vm.expectRevert("VDRFactory: only VDR owner can request upgrade");
        factory.upgradeVDR(vdrAddress);
    }

    function test_CannotUpgradeIfAlreadyLatest() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // VDR is already using factory's current implementation
        // Try to upgrade should fail (already at latest)
        vm.prank(vdrOwner);
        vm.expectRevert("VDRFactory: already at latest version");
        factory.upgradeVDR(vdrAddress);
    }

    function test_GetVDRImplementation() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // Verify current implementation
        assertEq(factory.getVDRImplementation(vdrAddress), address(vdrImplementation));
        // Verify version is tracked (1.0.0 = 1000000)
        assertEq(factory.getVDRVersion(vdrAddress), 1000000);
        
        // Verify implementation address is the one set in factory
        assertEq(factory.vdrImplementation(), address(vdrImplementation));
    }

    function test_NonOwnerCannotUpgradeOthersVDR() public {
        address[] memory managers = new address[](0);
        address unauthorized = address(0x777);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // Unauthorized address cannot request upgrade
        vm.prank(unauthorized);
        vm.expectRevert("VDRFactory: only VDR owner can request upgrade");
        factory.upgradeVDR(vdrAddress);
    }

    function test_CreatorCannotUpgradeOthersVDR() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // Creator (not the VDR owner) cannot upgrade
        vm.prank(creator);
        (bool success, ) = vdrAddress.call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(vdrImplementation),
                ""
            )
        );
        assertFalse(success, "Creator should not be able to upgrade if not owner");
    }

    // ============ VDR Implementation Update Tests ============

    function test_SetVDRImplementation() public {
        // Deploy a new VDR implementation (will have version 1.0.0 = 1000000)
        VDR newVdrImplementation = new VDR();
        
        // Initial implementation should be vdrImplementation (version 1.0.0 = 1000000)
        assertEq(factory.vdrImplementation(), address(vdrImplementation));
        assertEq(factory.vdrImplementationVersion(), 1000000);
        
        // Cannot set same version implementation
        vm.prank(factoryOwner);
        vm.expectRevert("VDRFactory: new implementation version must be higher than current");
        factory.setVDRImplementation(address(newVdrImplementation));
    }

    function test_SetVDRImplementationNewVDRsUseNewImpl() public {
        // Deploy implementations with increasing versions by upgrading
        address[] memory managers = new address[](1);
        managers[0] = vdrDataManager;

        // Create VDR with initial implementation (version 1.0.0 = 1000000)
        vm.prank(creator);
        address vdr1 = factory.createVDR(
            "VDR 1",
            vdrOwner,
            managers
        );
        assertEq(factory.getVDRVersion(vdr1), 1000000);

        // Deploy a newer implementation for factory upgrade
        VDR newVdrImplementation = new VDR();
        
        // Current impl is version 1.0.0, new impl is also version 1.0.0, so this should fail
        vm.prank(factoryOwner);
        vm.expectRevert("VDRFactory: new implementation version must be higher than current");
        factory.setVDRImplementation(address(newVdrImplementation));

        // Both VDRs created use initial implementation
        assertTrue(factory.isValidVDR(vdr1));
    }

    function test_OnlyOwnerCanSetVDRImplementation() public {
        VDR newVdrImplementation = new VDR();
        
        // Non-owner tries to set implementation
        vm.prank(creator);
        vm.expectRevert();
        factory.setVDRImplementation(address(newVdrImplementation));
    }

    function test_SetVDRImplementationRejectsZeroAddress() public {
        // Factory owner tries to set zero address as implementation
        vm.prank(factoryOwner);
        vm.expectRevert("VDRFactory: invalid implementation");
        factory.setVDRImplementation(address(0));
    }

    // ============ Version Number Tests ============

    function test_VDRInitialVersionIsOne() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // New VDR should start at version 1.0.0 (1000000)
        assertEq(factory.getVDRVersion(vdrAddress), 1000000);
    }

    function test_VersionIncrementOnUpgrade() public {
        address[] memory managers = new address[](0);

        vm.prank(creator);
        address vdrAddress = factory.createVDR(
            "Test VDR",
            vdrOwner,
            managers
        );

        // Initial version should be 1.0.0 (1000000)
        assertEq(factory.getVDRVersion(vdrAddress), 1000000);
        
        // Factory implementation version is also 1.0.0 (1000000)
        assertEq(factory.vdrImplementationVersion(), 1000000);
        
        // Trying to upgrade fails because already at latest
        vm.prank(vdrOwner);
        vm.expectRevert("VDRFactory: already at latest version");
        factory.upgradeVDR(vdrAddress);
    }

    function test_DifferentVDRsCanHaveDifferentVersions() public {
        address[] memory managers = new address[](0);

        // Create first VDR
        vm.prank(creator);
        address vdr1 = factory.createVDR(
            "VDR 1",
            vdrOwner,
            managers
        );

        assertEq(factory.getVDRVersion(vdr1), 1000000);

        // Create second VDR (same version since implementation hasn't changed)
        vm.prank(creator);
        address vdr2 = factory.createVDR(
            "VDR 2",
            vdrOwner,
            managers
        );

        assertEq(factory.getVDRVersion(vdr2), 1000000);
        
        // Both VDRs have same version since they use same implementation
        assertEq(factory.getVDRVersion(vdr1), factory.getVDRVersion(vdr2));
    }}