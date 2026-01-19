// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVDRProxy
 * @dev Interface for VDR proxy contract
 */
interface IVDRProxy {
    /**
     * @dev Upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @dev Upgrade to a new implementation and call a function
     * @param newImplementation Address of the new implementation
     * @param data Encoded function call data
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external;

    /**
     * @dev Get the current implementation address
     * @return Address of the current implementation
     */
    function implementation() external view returns (address);

    /**
     * @dev Get the current admin address
     * @return Address of the current admin
     */
    function admin() external view returns (address);

    /**
     * @dev Change the admin address
     * @param newAdmin Address of the new admin
     */
    function changeAdmin(address newAdmin) external;
}
