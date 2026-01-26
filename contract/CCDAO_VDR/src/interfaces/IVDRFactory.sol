// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVDRFactory
 * @dev Interface for VDR Factory contract
 */
interface IVDRFactory {
    // ============ Events ============

    event VDRCreated(
        address indexed vdrAddress,
        address indexed owner,
        address indexed creator
    );

    // ============ Factory Functions ============

    /**
     * @dev Create a new VDR instance using the latest implementation
     * @param name The name of the VDR
     * @param owner The owner address (can be a multisig contract like Safe)
     * @param verifiers Array of initial verifier addresses
     * @return vdrAddress The address of the created VDR
     */
    function createVDR(
        string calldata name,
        address owner,
        address[] calldata verifiers
    ) external returns (address);

    /**
     * @dev Update the current VDR implementation
     * New VDRs created after this will use the new implementation
     * Validates that the new implementation is compatible and starts at version 1
     * @param newImplementation Address of the new VDR implementation
     */
    function setVDRImplementation(address newImplementation) external;

    /**
     * @dev Upgrade a specific VDR to the latest implementation
     * Only the VDR owner can request this upgrade
     * @param vdrAddress Address of the VDR to upgrade
     */
    function upgradeVDR(address vdrAddress) external;

    // ============ Query Functions ============

    function getVDRCount() external view returns (uint256);

    function getVDRByIndex(uint256 index) external view returns (address);

    function getVDRsByCreator(address creator) external view returns (address[] memory);

    function isValidVDR(address vdrAddress) external view returns (bool);

    function getVDRImplementation(address vdrAddress) external view returns (address);

    function getVDRVersion(address vdrAddress) external view returns (uint256);

    function getVDRs(uint256 startIndex, uint256 endIndex) external view returns (address[] memory);

    function getVDRDetails(address vdrAddress)
        external
        view
        returns (
            string memory name,
            address owner,
            uint256 memberCount
        );
}
