// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VDR.sol";
import "../src/VDRFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployVDR is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy VDR implementation
        VDR vdrImpl = new VDR();
        console.log("VDR Implementation deployed at:", address(vdrImpl));

        // Deploy VDRFactory implementation
        VDRFactory factoryImpl = new VDRFactory();
        console.log("VDRFactory Implementation deployed at:", address(factoryImpl));

        // Deploy factory behind ERC1967Proxy with initialization
        address factoryOwner = msg.sender;
        bytes memory factoryInitData = abi.encodeCall(
            VDRFactory.initialize,
            (factoryOwner, address(vdrImpl))
        );
        
        ERC1967Proxy factoryProxy = new ERC1967Proxy(address(factoryImpl), factoryInitData);
        console.log("VDRFactory Proxy deployed at:", address(factoryProxy));

        // Example: Create a VDR instance
        VDRFactory factory = VDRFactory(address(factoryProxy));
        
        address vdrOwner = address(0x1);
        address[] memory dataManagers = new address[](1);
        dataManagers[0] = address(0x2);

        address vdrAddress = factory.createVDR(
            "MyVDR",
            vdrOwner,
            dataManagers
        );
        console.log("VDR deployed at:", vdrAddress);

        vm.stopBroadcast();
    }
}
