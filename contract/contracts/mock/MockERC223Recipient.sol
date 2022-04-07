// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/IERC223Recipient.sol";

contract MockERc223Recipient is IERC223Recipient {
  event Received(address _from, uint256 _value, bytes _data);

  function tokenReceived(address from, uint256 value, bytes calldata data) external override {
      // make something here ....
      emit Received(from, value, data);
  }
}
