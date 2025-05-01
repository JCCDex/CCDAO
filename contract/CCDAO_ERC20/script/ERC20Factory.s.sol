// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Factory} from "../src/ERC20Factory.sol";

contract ERC20FactoryScript is Script {
    // ERC20Factory public ERC20Factory;

    function setUp() public {}

    // forge script script/ERC20Factory.s.sol:ERC20FactoryScript --sig "deployCCDAO()" --chain chain_name --rpc-url rpc_node_server --broadcast -vvvv
    function deployCCDAO() public {
        deploy("Cross Chain DAO", "CCDAO", 18, 2000000000, true);
    }

    function deploy(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply, bool isMintable) public {
        vm.startBroadcast();

        ERC20Factory erc20FactoryInstance = new ERC20Factory(
            name, symbol, decimals, initialSupply, isMintable
        );

        console.log("ERC20Factory deployed at:", address(erc20FactoryInstance));
        vm.stopBroadcast();
    }
}
