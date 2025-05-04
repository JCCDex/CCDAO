// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, Vm, console} from "forge-std/Test.sol";
import "../src/ERC3525.sol";
import "../src/mocks/ERC3525BaseMock.sol";
import {ERC721ReceiverMock} from "../src/mocks/ERC721ReceiverMock.sol";
import "../src/mocks/NonReceiverMock.sol";

contract ERC721BehaviorTest is Test {
    ERC3525BaseMock private erc3525;
    ERC721ReceiverMock private erc721ReceiverMock;
    NonReceiverMock private nonReceiverMock;

    string name = 'Semi Fungible Token';
    string symbol = 'SFT';
    uint8 decimals = 18;
    bytes4 RECEIVER_MAGIC_VALUE = 0x150b7a02;

    address private owner = vm.addr(1);
    address private newOwner = vm.addr(2);
    address private approved = vm.addr(3);
    address private anotherApproved = vm.addr(4);
    address private operator = vm.addr(5);
    address private other = vm.addr(6);

    uint256 private constant TOKEN_ID_1 = 1001;
    uint256 private constant TOKEN_ID_2 = 1002;
    uint256 private constant nonExistentTokenId = 103;

    uint256 snapshotId; 

    function setUp() public {
        erc3525 = new ERC3525BaseMock(name, symbol, decimals);
        erc721ReceiverMock = new ERC721ReceiverMock(RECEIVER_MAGIC_VALUE, ERC721ReceiverMock.Error.None);
        nonReceiverMock = new NonReceiverMock();

        vm.startPrank(owner);
        erc3525.mint(owner, TOKEN_ID_1, 1, 0); // SLOT 1, balance 0
        erc3525.mint(owner, TOKEN_ID_2, 1, 0); // SLOT 1, balance 0

        erc3525.approve(approved, TOKEN_ID_1);
        erc3525.setApprovalForAll(operator, true);

        vm.stopPrank();
        snapshotId = vm.snapshotState();
    }

    // ------------------------------------------------------
    // test ERC721 behavior
    // ------------------------------------------------------
    function testBalanceOf() public {
        assertEq(erc3525.balanceOf(owner), 2);
        assertEq(erc3525.balanceOf(other), 0);

        vm.expectRevert("ERC3525: balance query for the zero address");
        erc3525.balanceOf(address(0));
    }

    function testOwnerOf() public {
        assertEq(erc3525.ownerOf(TOKEN_ID_1), owner);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.ownerOf(nonExistentTokenId);
    }

    // when called by the owner
    function testTransferByOwner() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), other);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called by the approved individual
    function testTransferByApprovedIndividual() public {
        vm.startPrank(approved);
        vm.recordLogs();
        // (tx = await transferFunction.call(this, owner.address, this.toWhom.address, tokenId, approved));
        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), other);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called by the operator
    function testTransferByOperator() public {
        vm.startPrank(operator);
        vm.recordLogs();
        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), other);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called by the operator without approved user
    function testTransferByOperatorWithoutApprovedUser() public {
        vm.startPrank(owner);
        erc3525.approve(address(0), TOKEN_ID_1);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.recordLogs();
        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), other);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called when sent to owner
    function testTransferWhenSentToOwner() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.transferFrom(owner, owner, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), owner);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));
        address _from = abi.decode(abi.encodePacked(logs[1].topics[1]), (address));
        address _to = abi.decode(abi.encodePacked(logs[1].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[1].topics[3]), (uint256));
        assertEq(_from, owner);
        assertEq(_to, owner);
        assertEq(_tokenId, TOKEN_ID_1);

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 2);

        assertEq(erc3525.tokenOfOwnerByIndex(owner, 1), TOKEN_ID_1);
        assertEq(erc3525.tokenOfOwnerByIndex(owner, 0), TOKEN_ID_2);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called when sent to previous owner
    function testTransferWhenPreviousOwner() public {
        vm.startPrank(owner);
        vm.recordLogs();
        vm.expectRevert("ERC3525: transfer from invalid owner");
        erc3525.transferFrom(other, other, TOKEN_ID_1);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called when sent to by not authorized owner
    function testTransferNotAuthorized() public {
        vm.startPrank(other);
        vm.recordLogs();
        vm.expectRevert("ERC3525: transfer caller is not owner nor approved");
        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called when sent none existent token
    function testTransferNonExistentToken() public {
        vm.startPrank(owner);
        vm.recordLogs();
        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.transferFrom(owner, other, nonExistentTokenId);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // when called when sent to zero address
    function testTransferToZeroAddress() public {
        vm.startPrank(owner);
        vm.recordLogs();
        vm.expectRevert("ERC3525: transfer to the zero address");
        erc3525.transferFrom(owner, address(0), TOKEN_ID_1);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data
    function testSafeTransferWithoutData() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.safeTransferFrom(owner, other, TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), other);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data via receiver
    function testSafeTransferWithoutDataViaReceiver() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.safeTransferFrom(owner, address(erc721ReceiverMock), TOKEN_ID_1);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), address(erc721ReceiverMock));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 3);
        assertEq(logs[1].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(logs[2].topics[0], keccak256("Received(address,address,uint256,bytes,uint256)"));
        //event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));
        assertEq(erc3525.balanceOf(owner), 1);

        assertEq(erc3525.tokenOfOwnerByIndex(address(erc721ReceiverMock), 0), TOKEN_ID_1);
        assertTrue(erc3525.tokenOfOwnerByIndex(owner, 0) != TOKEN_ID_1, "Token ID should not be in owner's index anymore");

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data to none receiver that implements ERC-165
    function testSafeTransferWithoutDataNoneReceiver() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        erc3525.safeTransferFrom(owner, address(erc3525), TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data to none receiver that does not implements ERC-165
    function testSafeTransferWithoutDataNoneReceiverNoneERC165() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        erc3525.safeTransferFrom(owner, address(nonReceiverMock), TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data to receiver unexpected value
    function testSafeTransferWithoutDataReceiverUnexpectedValue() public {
        vm.startPrank(owner);
        vm.recordLogs();
        ERC721ReceiverMock receiver = new ERC721ReceiverMock(0x12345678, ERC721ReceiverMock.Error.None);
        vm.expectRevert("ERC3525: transfer to non ERC721Receiver");
        erc3525.safeTransferFrom(owner, address(receiver), TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data to receiver that reverts with message
    function testSafeTransferWithoutDataReceiverRevertsMessage() public {
        vm.startPrank(owner);
        vm.recordLogs();
        ERC721ReceiverMock receiver = new ERC721ReceiverMock(RECEIVER_MAGIC_VALUE, ERC721ReceiverMock.Error.RevertWithMessage);
        vm.expectRevert("ERC721ReceiverMock: reverting");
        erc3525.safeTransferFrom(owner, address(receiver), TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test safeTransferFrom without data to receiver that panic
    function testSafeTransferWithoutDataPanic() public {
        vm.startPrank(owner);
        vm.recordLogs();
        ERC721ReceiverMock receiver = new ERC721ReceiverMock(RECEIVER_MAGIC_VALUE, ERC721ReceiverMock.Error.Panic);
        vm.expectRevert(abi.encodeWithSelector(0x4e487b71, uint256(0x12)));
        erc3525.safeTransferFrom(owner, address(receiver), TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testSafeMint() public {}
    function testApprove() public {}
    function testSetApprovalForAll() public {}
    function testGetApproved() public {}
    function testMint() public {}
    function testBurn() public {}

}