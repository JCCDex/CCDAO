// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
IERC223 Recipient call back hook definition
*/
interface IERC223Recipient {
  function tokenReceived(address from, uint256 value, bytes calldata data) external;
}
