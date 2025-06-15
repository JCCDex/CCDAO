// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AVA_Manager} from "../src/AVA_Manager.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AVA_ManagerScript is Script {    
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. 部署逻辑合约
        AVA_Manager impl = new AVA_Manager();

        // 2. 构造初始化数据
        bytes memory data = abi.encodeWithSelector(AVA_Manager.initialize.selector);

        // 3. 部署代理合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);

        proxy;
        
        vm.stopBroadcast();
    }
}
