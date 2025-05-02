// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ERC3525.sol";

contract ERC721BehaviorTest is Test {
    ERC3525 private erc3525;

    string name = 'Semi Fungible Token';
    string symbol = 'SFT';
    uint8 decimals = 18;

    address private owner = address(0x1);
    address private user1 = address(0x2);

    uint256 private constant TOKEN_ID_1 = 1001;
    uint256 private constant TOKEN_ID_2 = 1002;

    function setUp() public {
        // 部署 ERC3525 合约
        erc3525 = new ERC3525(name, symbol, decimals);

        // 模拟 owner 铸造代币
        vm.startPrank(owner);
        erc3525.mint(owner, TOKEN_ID_1, 1, 0); // SLOT 1, balance 0
        erc3525.mint(owner, TOKEN_ID_2, 1, 0); // SLOT 1, balance 0
        vm.stopPrank();
    }

}