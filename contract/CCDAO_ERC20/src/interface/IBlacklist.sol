// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
IBlacklist 对ERC20扩展黑名单能力
*/
interface IBlacklist {
  event DestroyedBlackFunds(address _blackListedUser, uint _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);

  function getBlackListStatus(address _maker) external view returns (bool);

  function addBlackList (address _evilUser) external;

  function removeBlackList (address _clearedUser) external;
}
