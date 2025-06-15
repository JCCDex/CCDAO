// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import {Test, Vm, console} from "forge-std/Test.sol";
import {ERC20Factory} from "../src/ERC20Factory.sol";
import {MockERC223Recipient} from "../src/mock/MockERC223Recipient.sol";

contract ERC20FactoryTest is Test {
    // used to take a snapshot of the current state of the blockchain
    uint256 snapshotId; 

    // ERC20Factory public erc20FactoryInstance;

    function setUp() public {
        snapshotId = vm.snapshotState();
    }

    // erc20 minable is false test case
    function testERC20Factory_minable_false() public {
        // Create an instance of the ERC20Factory contract
        vm.startPrank(vm.addr(1));
        ERC20Factory erc20FactoryInstance = new ERC20Factory(
            "JC Token", "JCC", 18, 2000000000, false
        );

        uint256 totalSupply = erc20FactoryInstance.totalSupply();
        assertEq(totalSupply, 2000000000 * 10**18, "Total supply should be 2000000000 * 10^18");

        address owner = erc20FactoryInstance.owner();
        address admin = erc20FactoryInstance.admin();
        assertEq(owner, admin, "Owner should be the same as admin");

        // transfer administrator to another address
        // vm.recordLogs();
        erc20FactoryInstance.transferAdministrator(vm.addr(2));
        // Vm.Log[] memory logs = vm.getRecordedLogs();
        admin = erc20FactoryInstance.admin();
        assertEq(vm.addr(1), owner);
        assertEq(vm.addr(2), admin);

        // transfer tokens to another address
        erc20FactoryInstance.transfer(vm.addr(3), 1000000000 * 10**18);
        uint256 balance1 = erc20FactoryInstance.balanceOf(vm.addr(1));
        uint256 balance3 = erc20FactoryInstance.balanceOf(vm.addr(3));
        assertEq(balance1, balance3, "account 1 balance should be equal to account 3 balance");


        // test zero account transfer
        vm.expectRevert("can not send to zero account");
        erc20FactoryInstance.transfer(address(0), 1000 ether);

        // transfer with insufficient balance
        vm.expectRevert("Not enough value");
        erc20FactoryInstance.transfer(vm.addr(2), 1000000001 * 10**18);

        vm.expectRevert("More than total supply");
        erc20FactoryInstance.transfer(vm.addr(2), 2000000001 * 10**18);

        vm.stopPrank(); // end address 1 prank

        // test approve function addr2 approve addr3 to spend 1000000000
        vm.startPrank(vm.addr(3));
        erc20FactoryInstance.approve(vm.addr(2), 1000000000 * 10**18);
        uint256 allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 1000000000 * 10**18, "Allowance should be 1000000000 * 10^18");
        vm.stopPrank(); // end address 3 prank

        // address 2 transfer from address 3 to address 4
        vm.startPrank(vm.addr(2));
        erc20FactoryInstance.transferFrom(vm.addr(3), vm.addr(4), 500000000 * 10**18);
        balance3 = erc20FactoryInstance.balanceOf(vm.addr(3));
        assertEq(balance3, 500000000 * 10**18, "account 3 balance should be equal to 500000000 * 10^18");
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 500000000 * 10**18, "Allowance should be 500000000 * 10^18");
        vm.stopPrank(); // end address 2 prank

        // adjust allowance
        vm.startPrank(vm.addr(3));
        erc20FactoryInstance.increaseAllowance(vm.addr(2), 250000000 * 10**18);
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 750000000 * 10**18, "Allowance should be 750000000 * 10^18");

        erc20FactoryInstance.decreaseAllowance(vm.addr(2), 50000000 * 10**18);
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 700000000 * 10**18, "Allowance should be 700000000 * 10^18");
        vm.stopPrank(); // end address 2 prank

        // test burn - should fail
        vm.startPrank(vm.addr(2));
        vm.expectRevert("minable must be true");        
        erc20FactoryInstance.burn(vm.addr(3), 500000000 * 10**18);
        totalSupply = erc20FactoryInstance.totalSupply();
        assertEq(totalSupply, 2000000000 * 10**18, "Total supply should be 1500000000 * 10^18");
        balance3 = erc20FactoryInstance.balanceOf(vm.addr(3));
        assertEq(balance3, 500000000 * 10**18, "account 3 balance should be equal to 0");

        // test black list
        erc20FactoryInstance.addBlackList(vm.addr(2));
        bool blackListStatus = erc20FactoryInstance.getBlackListStatus(vm.addr(2));
        assertEq(blackListStatus, true, "address 2 should be black listed");
        vm.stopPrank(); // end address 2 prank

        vm.revertToState(snapshotId);
    }

    // erc20 minable is true test case
    function testERC20Factory_minable_true() public {
        // Create an instance of the ERC20Factory contract
        vm.startPrank(vm.addr(1));
        ERC20Factory erc20FactoryInstance = new ERC20Factory(
            "JC Token", "JCC", 18, 2000000000, true
        );

        uint256 totalSupply = erc20FactoryInstance.totalSupply();
        assertEq(totalSupply, 0, "Total supply should be 0");

        address owner = erc20FactoryInstance.owner();
        address admin = erc20FactoryInstance.admin();
        assertEq(owner, admin, "Owner should be the same as admin");

        // transfer administrator to another address
        // vm.recordLogs();
        erc20FactoryInstance.transferAdministrator(vm.addr(2));
        // Vm.Log[] memory logs = vm.getRecordedLogs();
        admin = erc20FactoryInstance.admin();
        assertEq(vm.addr(1), owner);
        assertEq(vm.addr(2), admin);

        // test mint
        erc20FactoryInstance.mint(vm.addr(3), 1000000000 * 10**18);
        totalSupply = erc20FactoryInstance.totalSupply();
        assertEq(totalSupply, 1000000000 * 10**18, "Total supply should be 1000000000 * 10^18");
        vm.stopPrank(); // end address 1 prank

        // transfer tokens to another address
        vm.startPrank(vm.addr(3));
        erc20FactoryInstance.transfer(vm.addr(4), 500000000 * 10**18);
        uint256 balance3 = erc20FactoryInstance.balanceOf(vm.addr(3));
        uint256 balance4 = erc20FactoryInstance.balanceOf(vm.addr(4));
        assertEq(balance3, balance4, "account 3 balance should be equal to account 4 balance");

        // test zero account transfer
        vm.expectRevert("can not send to zero account");
        erc20FactoryInstance.transfer(address(0), 1000 ether);

        // transfer with insufficient balance
        vm.expectRevert("Not enough value");
        erc20FactoryInstance.transfer(vm.addr(2), 500000001 * 10**18);

        vm.expectRevert("More than total supply");
        erc20FactoryInstance.transfer(vm.addr(2), 2000000001 * 10**18);

        // test approve function
        erc20FactoryInstance.approve(vm.addr(2), 500000000 * 10**18);
        uint256 allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 500000000 * 10**18, "Allowance should be 500000000 * 10^18");

        vm.stopPrank(); // end address 3 prank

        // address 2 transfer from address 3 to address 4
        vm.startPrank(vm.addr(2));
        erc20FactoryInstance.transferFrom(vm.addr(3), vm.addr(4), 250000000 * 10**18);
        balance3 = erc20FactoryInstance.balanceOf(vm.addr(3));
        assertEq(balance3, 250000000 * 10**18, "account 3 balance should be equal to 250000000 * 10^18");
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 250000000 * 10**18, "Allowance should be 250000000 * 10^18");
        vm.stopPrank(); // end address 2 prank

        // adjust allowance
        vm.startPrank(vm.addr(3));
        erc20FactoryInstance.increaseAllowance(vm.addr(2), 250000000 * 10**18);
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 500000000 * 10**18, "Allowance should be 500000000 * 10^18");

        erc20FactoryInstance.decreaseAllowance(vm.addr(2), 250000000 * 10**18);
        allowance = erc20FactoryInstance.allowance(vm.addr(3), vm.addr(2));
        assertEq(allowance, 250000000 * 10**18, "Allowance should be 250000000 * 10^18");
        vm.stopPrank(); // end address 2 prank

        // test burn
        vm.startPrank(vm.addr(2));
        erc20FactoryInstance.burn(vm.addr(3), 250000000 * 10**18);
        totalSupply = erc20FactoryInstance.totalSupply();
        assertEq(totalSupply, 750000000 * 10**18, "Total supply should be 750000000 * 10^18");
        balance4 = erc20FactoryInstance.balanceOf(vm.addr(4));
        assertEq(balance4, 750000000 * 10**18, "account 4 balance should be equal to 750000000 * 10^18");

        // test black list
        erc20FactoryInstance.addBlackList(vm.addr(4));
        bool blackListStatus = erc20FactoryInstance.getBlackListStatus(vm.addr(4));
        assertEq(blackListStatus, true, "address 4 should be black listed");

        erc20FactoryInstance.removeBlackList(vm.addr(4));
        blackListStatus = erc20FactoryInstance.getBlackListStatus(vm.addr(4));
        assertEq(blackListStatus, false, "address 4 should not be black listed");
        vm.stopPrank(); // end address 2 prank

        // test erc223
        vm.startPrank(vm.addr(4));
        vm.recordLogs();
        MockERC223Recipient receiver = new MockERC223Recipient();
        erc20FactoryInstance.transfer(
            address(receiver),
            100000000 * 10**18,
            "0x2233"
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 3);
        assertEq(logs[1].topics[0], keccak256("Received(address,uint256,bytes)"));

        uint256 balance = erc20FactoryInstance.balanceOf(address(receiver));
        assertEq(balance, 100000000 * 10**18, "account 4 balance should be equal to 100000000 * 10^18");
        vm.stopPrank(); // end address 4 prank

        vm.revertToState(snapshotId);
    }
}