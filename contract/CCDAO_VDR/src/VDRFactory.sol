// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VDR.sol";
import "./interfaces/IVDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ICCDAO_CREATE2 {
    function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address);
    function predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address);
}

/**
 * @title VDRFactory
 * @dev Factory for creating and managing VDR instances with UUPS upgrade support
 * 
 * This factory is deployed behind an ERC1967Proxy and supports upgrades via UUPSUpgradeable.
 * When VDR receives interface changes, Factory is upgraded alongside it.
 * 
 * Upgrade Flow:
 * 1. Deploy new VDRFactory implementation
 * 2. Call proxy.upgradeToAndCall() with new implementation and init calldata (if needed)
 * 3. Factory code is updated atomically
 * 
 * @author CCDAO Team
 */
contract VDRFactory is IVDRFactory, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ============ State Variables ============

    address[] private vdrInstances;
    mapping(address => bool) private validVDRs;
    mapping(address => address[]) private creatorVDRs;
    mapping(address => address) private vdrImplementations;  // Track each VDR's current implementation
    mapping(address => uint256) private vdrVersions;  // Track version number for each VDR
    
    address public vdrImplementation;  // Current VDR implementation address
    uint256 public vdrImplementationVersion;  // Current VDR implementation version
    address public ccdaoCreate2;  // CCDAO_CREATE2 factory for deterministic proxy deployment

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ Initialization ============

    /**
     * @dev Initialize the VDRFactory contract
     * Must be called once after proxy deployment
     * Dynamically reads the version from the initial implementation
     * @param initialOwner The initial owner of the factory
     * @param initialImplementation The initial VDR implementation address
     * @param ccdaoCreate2Address The CCDAO_CREATE2 factory for deterministic proxy deployment
     */
    function initialize(address initialOwner, address initialImplementation, address ccdaoCreate2Address) public initializer {
        require(initialImplementation != address(0), "VDRFactory: invalid initial implementation");
        require(ccdaoCreate2Address != address(0), "VDRFactory: invalid CCDAO_CREATE2 address");
        
        __Ownable_init(initialOwner);
        vdrImplementation = initialImplementation;
        ccdaoCreate2 = ccdaoCreate2Address;
        
        // Dynamically get version from the initial implementation
        // This ensures version consistency without manual synchronization
        (bool success, bytes memory result) = initialImplementation.staticcall(
            abi.encodeWithSelector(VDR.getVersion.selector)
        );
        require(success, "VDRFactory: failed to read version from initial implementation");
        require(result.length == 32, "VDRFactory: invalid version data from initial implementation");
        
        uint256 implVersion = abi.decode(result, (uint256));
        // Implementation version must be greater than 0
        require(implVersion > 0, "VDRFactory: implementation version must be greater than 0");
        vdrImplementationVersion = implVersion;
    }

    // ============ Factory Functions ============

    /**
     * @dev Create a new VDR instance using the latest implementation
     * VDR proxy address is deterministic based on DAO name (via CREATE2)
     * @param name The name of the VDR (also used as salt for deterministic proxy deployment)
     * @param owner The owner address (can be a multisig contract like Safe)
     * @param verifiers Array of initial verifier addresses
     * @return vdrAddress The address of the created VDR proxy (deterministic based on name)
     */
    function createVDR(
        string calldata name,
        address owner,
        address[] calldata verifiers
    ) external returns (address) {
        require(owner != address(0), "VDRFactory: invalid owner address");
        require(bytes(name).length > 0, "VDRFactory: DAO name cannot be empty");

        // Encode initialization data using VDR interface
        bytes memory initData = abi.encodeWithSelector(
            VDR.initialize.selector,
            name,
            owner,
            verifiers
        );
        
        // Predict the deterministic address before deployment
        // Generate salt from daoName and caller (msg.sender) - caller cannot be forged
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender));
        
        // Calculate the actual bytecode that will be deployed
        // This must match exactly what _createVDRWithData will deploy
        bytes memory proxyBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(vdrImplementation, initData)
        );
        bytes32 bytecodeHash = keccak256(proxyBytecode);
        
        ICCDAO_CREATE2 factory = ICCDAO_CREATE2(ccdaoCreate2);
        address predictedAddress = factory.predictAddress(salt, bytecodeHash);
        
        // Check if this address is already in use (prevent DAO name collision)
        require(!validVDRs[predictedAddress], "VDRFactory: VDR for this DAO name already exists");
        
        return _createVDRWithData(vdrImplementation, initData, owner, salt, msg.sender);
    }

    /**
     * @dev Update the current VDR implementation
     * Only factory owner can call this
     * Validates that the new implementation is compatible and has a higher version
     * @param newImplementation Address of the new VDR implementation
     */
    function setVDRImplementation(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "VDRFactory: invalid implementation");
        
        // Verify new implementation has getVersion method using staticcall
        (bool success, bytes memory result) = newImplementation.staticcall(
            abi.encodeWithSelector(VDR.getVersion.selector)
        );
        require(success, "VDRFactory: invalid implementation - missing getVersion() method");
        require(result.length == 32, "VDRFactory: invalid implementation - getVersion() returned unexpected data");
        
        // Decode the version from the result
        uint256 newVersion = abi.decode(result, (uint256));
        
        // Verify new version is greater than 0
        require(newVersion > 0, "VDRFactory: implementation version must be greater than 0");
        
        // Verify getImplementation method exists
        (success, ) = newImplementation.staticcall(
            abi.encodeWithSelector(VDR.getImplementation.selector)
        );
        require(success, "VDRFactory: invalid implementation - missing getImplementation() method");
        
        // Verify new version is higher than current version
        require(newVersion > vdrImplementationVersion, "VDRFactory: new implementation version must be higher than current");
        
        vdrImplementation = newImplementation;
        vdrImplementationVersion = newVersion;
    }

    // ============ Query Functions ============

    /**
     * @dev Get the total number of VDRs created
     * @return Total count of VDR instances
     */
    function getVDRCount() external view returns (uint256) {
        return vdrInstances.length;
    }

    /**
     * @dev Get a VDR address by index
     * @param index The index in the VDR instances array
     * @return The address of the VDR at the given index
     */
    function getVDRByIndex(uint256 index) external view returns (address) {
        require(index < vdrInstances.length, "VDRFactory: index out of bounds");
        return vdrInstances[index];
    }

    /**
     * @dev Get all VDRs created by a specific address
     * @param creator The creator address
     * @return Array of VDR addresses created by this address
     */
    function getVDRsByCreator(address creator) external view returns (address[] memory) {
        return creatorVDRs[creator];
    }

    /**
     * @dev Check if an address is a valid VDR
     * @param vdrAddress Address to check
     * @return True if the address is a valid VDR created by this factory
     */
    function isValidVDR(address vdrAddress) external view returns (bool) {
        return validVDRs[vdrAddress];
    }

    /**
     * @dev Get all created VDRs within a range
     * @param startIndex The starting index (inclusive)
     * @param endIndex The ending index (exclusive)
     * @return Array of VDR addresses in the specified range
     */
    function getVDRs(uint256 startIndex, uint256 endIndex) external view returns (address[] memory) {
        require(startIndex <= endIndex, "VDRFactory: invalid range");
        require(endIndex <= vdrInstances.length, "VDRFactory: endIndex out of bounds");
        
        uint256 length = endIndex - startIndex;
        address[] memory result = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = vdrInstances[startIndex + i];
        }
        
        return result;
    }

    /**
     * @dev Get VDR details
     * @param vdrAddress Address of the VDR
     * @return name Name of the VDR
     * @return owner Owner address of the VDR
     * @return memberCount Number of members
     */
    function getVDRDetails(address vdrAddress)
        external
        view
        returns (
            string memory name,
            address owner,
            uint256 memberCount
        )
    {
        require(validVDRs[vdrAddress], "VDRFactory: invalid VDR address");

        VDR vdr = VDR(vdrAddress);
        return (
            vdr.vdrName(),
            vdr.owner(),
            vdr.getMemberCount()
        );
    }

    /**
     * @dev Get the current implementation of a specific VDR
     * @param vdrAddress Address of the VDR proxy
     * @return Address of the current implementation
     */
    function getVDRImplementation(address vdrAddress) external view returns (address) {
        require(validVDRs[vdrAddress], "VDRFactory: invalid VDR address");
        return vdrImplementations[vdrAddress];
    }

    /**
     * @dev Get the version number of a specific VDR
     * @param vdrAddress Address of the VDR proxy
     * @return Version number of this VDR instance
     */
    function getVDRVersion(address vdrAddress) external view returns (uint256) {
        require(validVDRs[vdrAddress], "VDRFactory: invalid VDR address");
        return vdrVersions[vdrAddress];
    }

    // ============ Upgrade Functions ============

    /**
     * @dev Upgrade a specific VDR to the latest implementation
     * Only the VDR owner can request the upgrade
     * The VDR will be upgraded to the current vdrImplementation version
     * Directly reads the VDR's version to prevent version regression
     * @param vdrAddress Address of the VDR to upgrade
     */
    function upgradeVDR(address vdrAddress) external {
        require(validVDRs[vdrAddress], "VDRFactory: invalid VDR address");
        
        // Verify caller is the VDR owner
        VDR vdr = VDR(vdrAddress);
        require(msg.sender == vdr.owner(), "VDRFactory: only VDR owner can request upgrade");
        
        address newImpl = vdrImplementation;
        require(newImpl != address(0), "VDRFactory: invalid implementation");
        
        // Directly read VDR's current implementation to check if upgrade is needed
        address currentImpl = vdr.getImplementation();
        require(newImpl != currentImpl, "VDRFactory: already at latest version");
        
        // Call upgradeToAndCall on the VDR proxy
        // VDR's _authorizeUpgrade will verify msg.sender == factory
        (bool success, ) = vdrAddress.call(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", newImpl, "")
        );
        require(success, "VDRFactory: upgrade failed");
        
        // Update tracked implementation (version is already updated in VDR._authorizeUpgrade)
        vdrImplementations[vdrAddress] = newImpl;
        vdrVersions[vdrAddress] = vdr.getVersion();  // Sync version
    }

    // ============ Utility Functions ============

    /**
     * @dev Internal function to create VDR proxy instance
     * Uses CREATE2 for deterministic proxy deployment based on DAO name and caller
     * @param vdrImpl Address of VDR implementation to deploy as proxy
     * @param initData Encoded initialization data
     * @param owner The owner address
     * @param salt The pre-calculated salt (daoName + caller hash)
     * @param caller The caller address (msg.sender, unforgeable)
     * @return vdrAddress The address of the created VDR proxy
     */
    function _createVDRWithData(
        address vdrImpl,
        bytes memory initData,
        address owner,
        bytes32 salt,
        address caller
    ) internal returns (address) {
        require(vdrImpl != address(0), "VDRFactory: invalid VDR implementation");
        require(ccdaoCreate2 != address(0), "VDRFactory: CCDAO_CREATE2 not set");
        
        // Create proxy bytecode with encoded constructor arguments
        // This includes the ERC1967Proxy creation code + initialization parameters
        bytes memory proxyBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(vdrImpl, initData)
        );
        
        // Deploy proxy via CREATE2 using CCDAO_CREATE2 factory
        ICCDAO_CREATE2 factory = ICCDAO_CREATE2(ccdaoCreate2);
        address vdrAddress = factory.deploy(proxyBytecode, salt);
        require(vdrAddress != address(0), "VDRFactory: VDR proxy deployment failed");

        // Register the VDR
        vdrInstances.push(vdrAddress);
        validVDRs[vdrAddress] = true;
        creatorVDRs[caller].push(vdrAddress);
        vdrImplementations[vdrAddress] = vdrImpl;  // Record the initial implementation
        vdrVersions[vdrAddress] = vdrImplementationVersion;  // Initialize version from current implementation version

        emit VDRCreated(vdrAddress, owner, caller);

        return vdrAddress;
    }

    // ============ Upgrade Authorization ============

    /**
     * @dev Authorize an upgrade to a new implementation
     * Only the owner can authorize upgrades
     * @param newImplementation The address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), "VDRFactory: invalid implementation");
    }
}
