// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CCDAO_ERC721} from "../src/CCDAO_ERC721.sol";

contract CCDAO_ERC721Script is Script {
    // Counter public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // counter = new Counter();

        vm.stopBroadcast();
    }
}
