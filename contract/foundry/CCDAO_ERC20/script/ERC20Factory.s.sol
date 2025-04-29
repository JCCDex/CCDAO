// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Factory} from "../src/ERC20Factory.sol";

contract ERC20FactoryScript is Script {
    // ERC20Factory public ERC20Factory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ERC20Factory erc20FactoryInstance = new ERC20Factory(
            "JC Token", "JCC", 18, 2000000000, false
        );

        vm.stopBroadcast();
    }
}
