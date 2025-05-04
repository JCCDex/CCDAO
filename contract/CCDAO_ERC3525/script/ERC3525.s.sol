// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC3525} from "../src/ERC3525.sol";
// TODO: need check deployment
contract ERC3525Script is Script {
    ERC3525 public erc3525;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        erc3525 = new ERC3525('Semi Fungible Token', 'SFT', 18);

        vm.stopBroadcast();
    }
}
