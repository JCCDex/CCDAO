// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../AVA_Manager.sol";

contract AVA_ManagerV2 is AVA_Manager {
    // 新增变量
    uint256 public newFeatureFlag;

    // 新增功能
    function setNewFeatureFlag(uint256 v) external {
        newFeatureFlag = v;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
