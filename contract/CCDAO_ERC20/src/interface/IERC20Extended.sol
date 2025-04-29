// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

/**
IERC20Extended 对ERC20标准扩展的一个接口定义
 */
interface IERC20Extended is IERC20 {
  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool);

  function mint(address account, uint256 value) external returns (bool);

  function burn(address account, uint256 value) external returns (bool);

  event Mint(address indexed account, uint256 value);

  event Burn(address indexed account, uint256 value);
}
