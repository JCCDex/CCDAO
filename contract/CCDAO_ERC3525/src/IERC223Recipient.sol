// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC223 recipient contract
interface IERC223Recipient {
    function tokenReceived(address from, uint256 value, bytes calldata data) external;
}