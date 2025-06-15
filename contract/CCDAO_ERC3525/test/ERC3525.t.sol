// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, Vm, console} from "forge-std/Test.sol";
import "../src/ERC3525.sol";
import "../src/mocks/ERC3525BaseMock.sol";
import {ERC3525ReceiverMock} from "../src/mocks/ERC3525ReceiverMock.sol";
import "../src/mocks/NonReceiverMock.sol";

contract ERC721BehaviorTest is Test {
    ERC3525BaseMock private erc3525;
    ERC3525ReceiverMock private erc3525ReceiverMock;
    NonReceiverMock private nonReceiverMock;

    uint256 private constant MAX_UINT256 = type(uint256).max;

    uint256 private constant firstSlot = 11;
    uint256 private constant secondSlot = 22;
    uint256 private constant nonExistentSlot = 99;

    uint256 private constant firstTokenId = 1001;
    uint256 private constant secondTokenId = 1002;
    uint256 private constant thirdTokenId = 2001;
    uint256 private constant fourthTokenId = 2002;
    uint256 private constant nonExistentTokenId = 9901;

    uint256 private constant firstTokenValue = 1000000;
    uint256 private constant secondTokenValue = 2000000;
    uint256 private constant thirdTokenValue = 3000000;
    uint256 private constant fourthTokenValue = 4000000;

    bytes4 RECEIVER_MAGIC_VALUE = 0x009ce20b;

    address private firstOwner = vm.addr(1);
    address private secondOwner = vm.addr(2);
    address private newOwner = vm.addr(3);
    address private approved = vm.addr(4);
    address private valueApproved = vm.addr(5);
    address private anotherApproved = vm.addr(6);
    address private operator = vm.addr(7);
    address private slotOperator = vm.addr(8);
    address private other = vm.addr(9);
    address private toWhom;

    string name = 'Semi Fungible Token';
    string symbol = 'SFT';
    uint8 decimals = 18;
    string baseURI = 'https://api.example.com/v1/';

    uint256 snapshotId; 

    function setUp() public {
        erc3525 = new ERC3525BaseMock(name, symbol, decimals);
        erc3525ReceiverMock = new ERC3525ReceiverMock(RECEIVER_MAGIC_VALUE, ERC3525ReceiverMock.Error.None);
        nonReceiverMock = new NonReceiverMock();

        vm.startPrank(firstOwner);
        erc3525.mint(firstOwner, firstTokenId, firstSlot, firstTokenValue);
        erc3525.mint(secondOwner, secondTokenId, firstSlot, secondTokenValue);
        erc3525.mint(firstOwner, thirdTokenId, secondSlot, thirdTokenValue);
        erc3525.mint(secondOwner, fourthTokenId, secondSlot, fourthTokenValue);
        toWhom = other;

        // erc3525.approve(approved, TOKEN_ID_1);
        // erc3525.setApprovalForAll(operator, true);

        vm.stopPrank();
        snapshotId = vm.snapshotState();
    }

    // ------------------------------------------------------
    // test ERC3525 behavior
    // ------------------------------------------------------    
    function testBalanceOf() public {
        assertEq(erc3525.balanceOf(firstTokenId), firstTokenValue);
        assertEq(erc3525.balanceOf(secondTokenId), secondTokenValue);
        assertEq(erc3525.balanceOf(thirdTokenId), thirdTokenValue);
        assertEq(erc3525.balanceOf(fourthTokenId), fourthTokenValue);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.balanceOf(0);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.balanceOf(nonExistentTokenId);
    }

    function testSlotOf() public {
        assertEq(erc3525.slotOf(firstTokenId), firstSlot);
        assertEq(erc3525.slotOf(secondTokenId), firstSlot);
        assertEq(erc3525.slotOf(thirdTokenId), secondSlot);
        assertEq(erc3525.slotOf(fourthTokenId), secondSlot);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.balanceOf(0);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.balanceOf(nonExistentTokenId);
    }

    // transfer from token to token
    function testTransferFromTokenToTokenByUsers() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[3].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[3].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[3].topics[2]), (uint256));
        uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);
        assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromTokenToTokenApprovedIndividual() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        vm.stopPrank();

        vm.startPrank(approved);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[3].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[3].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[3].topics[2]), (uint256));
        uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);
        assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueApprovedIndividual() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);
        uint256 allowanceBefore = erc3525.allowance(firstTokenId, valueApproved);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        vm.stopPrank();
        
        vm.startPrank(valueApproved);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 5);
        assertEq(logs[4].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[4].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[4].topics[2]), (uint256));
        // uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);
        // assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        uint256 allowanceAfter = erc3525.allowance(firstTokenId, valueApproved);
        assertEq(allowanceAfter, allowanceBefore - transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromUnlimitValueApprovedIndividual() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, MAX_UINT256);
        erc3525.setApprovalForAll(operator, true);
        uint256 allowanceBefore = erc3525.allowance(firstTokenId, valueApproved);
        assertEq(allowanceBefore, MAX_UINT256);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        vm.stopPrank();
        
        vm.startPrank(valueApproved);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[3].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[3].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[3].topics[2]), (uint256));
        // uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);
        // assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        uint256 allowanceAfter = erc3525.allowance(firstTokenId, valueApproved);
        assertEq(allowanceAfter, MAX_UINT256);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueByOperator() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        vm.stopPrank();
        
        vm.startPrank(operator);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[3].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[3].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[3].topics[2]), (uint256));
        // uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);
        // assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueByOperatorWithoutApprovedUser() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);
        erc3525.approve(address(0), firstTokenId);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toTokenId = secondTokenId;
        uint256 toTokenValue = secondTokenValue;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        vm.stopPrank();
        
        vm.startPrank(operator);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        assertEq(erc3525.balanceOf(toTokenId), toTokenValue + transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 5);
        assertEq(logs[4].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[4].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[4].topics[2]), (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, toTokenId);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(toOwner), toOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.ownerOf(toTokenId), toOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueItself() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        uint256 toTokenId = secondTokenId;

        vm.stopPrank();
        
        vm.startPrank(fromOwner);

        // shouldTransferValueFromTokenToTokenByUsers
        erc3525.transferFrom(fromTokenId, fromTokenId, transferValue);

        // transferValueFromTokenToTokenWasSuccessful
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[3].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));
        uint256 _fromTokenId = abi.decode(abi.encodePacked(logs[3].topics[1]), (uint256));
        uint256 _toTokenId = abi.decode(abi.encodePacked(logs[3].topics[2]), (uint256));
        uint256 _value = abi.decode(logs[3].data, (uint256));
        assertEq(_fromTokenId, fromTokenId);
        assertEq(_toTokenId, fromTokenId);
        assertEq(_value, transferValue);

        // do not adjust owners balances
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);

        // do not adjust token owners
        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);

        // do not adjust tokens slots
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        // transferValueFromTokenToTokenWasSuccessful --- end

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueExceedLittle() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;

        uint256 toTokenId = secondTokenId;

        vm.stopPrank();
        
        vm.startPrank(fromOwner);

        vm.expectRevert("ERC3525: insufficient balance for transfer");
        erc3525.transferFrom(fromTokenId, toTokenId, fromTokenValue + 1);


        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueDifferentSlot() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;

        vm.stopPrank();
        
        vm.startPrank(fromOwner);

        vm.expectRevert("ERC3525: transfer to token with different slot");
        erc3525.transferFrom(fromTokenId, thirdTokenId, transferValue);


        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueInvalid() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;

        vm.stopPrank();
        
        vm.startPrank(fromOwner);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.transferFrom(nonExistentTokenId, thirdTokenId, transferValue);

        vm.expectRevert("ERC3525: transfer to invalid token ID");
        erc3525.transferFrom(fromTokenId, nonExistentTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueNoAuthorized() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        uint256 fromTokenId = firstTokenId;

        vm.stopPrank();
        
        vm.startPrank(other);

        vm.expectRevert("ERC3525: insufficient allowance");
        erc3525.transferFrom(fromTokenId, thirdTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueExceedsAllownace() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, transferValue - 1);

        uint256 fromTokenId = firstTokenId;

        vm.stopPrank();
        
        vm.startPrank(valueApproved);

        vm.expectRevert("ERC3525: insufficient allowance");
        erc3525.transferFrom(fromTokenId, thirdTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueReciverContractReturnUnexpectValue() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        ERC3525ReceiverMock receiver = new ERC3525ReceiverMock(0x12345678, ERC3525ReceiverMock.Error.None);
        address toOwner = address(receiver);
        uint256 toTokenId = 1003;
        uint256 toTokenValue = 100000;
        erc3525.mint(toOwner, toTokenId, firstSlot, toTokenValue);

        uint256 transferValue = 100;
        uint256 fromTokenId = firstTokenId;

        vm.expectRevert("ERC3525: transfer rejected by ERC3525Receiver");
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueReciverContracRevertWithMessage() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        ERC3525ReceiverMock receiver = new ERC3525ReceiverMock(RECEIVER_MAGIC_VALUE, ERC3525ReceiverMock.Error.RevertWithMessage);
        address toOwner = address(receiver);
        uint256 toTokenId = 1003;
        uint256 toTokenValue = 100000;
        erc3525.mint(toOwner, toTokenId, firstSlot, toTokenValue);

        uint256 transferValue = 100;
        uint256 fromTokenId = firstTokenId;

        vm.expectRevert("ERC3525ReceiverMock: reverting");
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueReciverContracRevertWithoutMessage() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        ERC3525ReceiverMock receiver = new ERC3525ReceiverMock(RECEIVER_MAGIC_VALUE, ERC3525ReceiverMock.Error.RevertWithoutMessage);
        address toOwner = address(receiver);
        uint256 toTokenId = 1003;
        uint256 toTokenValue = 100000;
        erc3525.mint(toOwner, toTokenId, firstSlot, toTokenValue);

        uint256 transferValue = 100;
        uint256 fromTokenId = firstTokenId;

        vm.expectRevert();
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueReciverContracPanic() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        ERC3525ReceiverMock receiver = new ERC3525ReceiverMock(RECEIVER_MAGIC_VALUE, ERC3525ReceiverMock.Error.Panic);
        address toOwner = address(receiver);
        uint256 toTokenId = 1003;
        uint256 toTokenValue = 100000;
        erc3525.mint(toOwner, toTokenId, firstSlot, toTokenValue);

        uint256 transferValue = 100;
        uint256 fromTokenId = firstTokenId;

        vm.expectRevert(abi.encodeWithSelector(0x4e487b71, uint256(0x12)));
        erc3525.transferFrom(fromTokenId, toTokenId, transferValue);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddress() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);

        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 7);
        assertEq(logs[3].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[4].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[5].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddressApprove() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);
        vm.stopPrank();

        vm.startPrank(approved);
        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 7);
        assertEq(logs[3].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[4].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[5].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddressValueApprove() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);
        vm.stopPrank();

        vm.startPrank(valueApproved);
        uint256 allowanceBefore = erc3525.allowance(fromTokenId, valueApproved);
        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 8);
        assertEq(logs[4].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[5].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[6].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);

        uint256 allowanceAfter = erc3525.allowance(fromTokenId, valueApproved);
        assertEq(allowanceAfter, allowanceBefore - transferValue);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddressUnlimitValueApprove() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, MAX_UINT256);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);
        vm.stopPrank();

        vm.startPrank(valueApproved);
        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 7);
        assertEq(logs[3].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[4].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[5].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);

        assertEq(erc3525.allowance(fromTokenId, valueApproved), MAX_UINT256);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddressOperator() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(approved, firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);
        vm.stopPrank();

        vm.startPrank(operator);
        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 7);
        assertEq(logs[3].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[4].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[5].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testTransferFromValueToAddressOperatorWithoutApprove() public {
        vm.startPrank(firstOwner);
        vm.recordLogs();

        uint256 transferValue = 100;
        erc3525.approve(address(0), firstTokenId);
        erc3525.approve(firstTokenId, valueApproved, firstTokenValue);
        erc3525.setApprovalForAll(operator, true);

        address fromOwner = firstOwner;
        uint256 fromTokenId = firstTokenId;
        uint256 fromTokenValue = firstTokenValue;
        uint256 fromOwnerBalance = erc3525.balanceOf(fromOwner);

        address toOwner = secondOwner;
        uint256 toOwnerBalance = erc3525.balanceOf(toOwner);
        vm.stopPrank();

        vm.startPrank(operator);
        erc3525.transferFrom(fromTokenId, toOwner, transferValue);
        assertEq(erc3525.balanceOf(fromOwner), fromOwnerBalance);
        assertEq(erc3525.balanceOf(fromTokenId), fromTokenValue - transferValue);
        uint256 toTokenId = erc3525.tokenOfOwnerByIndex(toOwner, toOwnerBalance);
        assertEq(erc3525.balanceOf(toTokenId), transferValue);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 7);
        assertEq(logs[3].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[4].topics[0], keccak256("SlotChanged(uint256,uint256,uint256)"));
        assertEq(logs[5].topics[0], keccak256("TransferValue(uint256,uint256,uint256)"));

        assertEq(erc3525.ownerOf(fromTokenId), fromOwner);
        assertEq(erc3525.slotOf(fromTokenId), firstSlot);
        assertEq(erc3525.slotOf(toTokenId), firstSlot);
        
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }
    // ------------------------------------------------------
    // test ERC3525 Metadata behavior
    // ------------------------------------------------------

    // ------------------------------------------------------
    // test ERC3525 Slot Enumerable
    // ------------------------------------------------------

    // ------------------------------------------------------
    // test ERC3525 Slot Approvable
    // ------------------------------------------------------
}