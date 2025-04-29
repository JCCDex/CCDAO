// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
IERC223 对ERC223标准的一个接口定义,兼容ERC20
*/
interface IERC223 {
  function standard() external view returns (string memory);

  function transfer(address to, uint256 value, bytes calldata data) external returns (bool);
     
  event TransferData(bytes data);
}
