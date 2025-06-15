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
    string baseURI = 'https://api.example.com/v1/';

    address private owner = vm.addr(1);
    address private newOwner = vm.addr(2);
    address private approved = vm.addr(3);
    address private anotherApproved = vm.addr(4);
    address private operator = vm.addr(5);
    address private other = vm.addr(6);

    uint256 private constant TOKEN_ID_1 = 1001;
    uint256 private constant TOKEN_ID_2 = 1002;
    uint256 private constant TOKEN_ID_3 = 1003;
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

    // test approve when clearing
    function testApproveWhenClearing() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.approve(address(0x0), TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

        assertEq(logs[0].topics[0], keccak256("Approval(address,address,uint256)"));
        address _owner = abi.decode(abi.encodePacked(logs[0].topics[1]), (address));
        address _approved = abi.decode(abi.encodePacked(logs[0].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[0].topics[3]), (uint256));
        assertEq(_owner, owner);
        assertEq(_approved, address(0));
        assertEq(_tokenId, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approve when prior approval
    function testApproveWhenPriorApproval() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.approve(approved, TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), approved);
        erc3525.approve(address(0), TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), address(0));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

        assertEq(logs[0].topics[0], keccak256("Approval(address,address,uint256)"));
        address _owner = abi.decode(abi.encodePacked(logs[0].topics[1]), (address));
        address _approved = abi.decode(abi.encodePacked(logs[0].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[0].topics[3]), (uint256));
        assertEq(_owner, owner);
        assertEq(_approved, approved);
        assertEq(_tokenId, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approve to same address
    function testApproveSameAddress() public {
        vm.startPrank(owner);
        vm.recordLogs();
        erc3525.approve(approved, TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), approved);
        erc3525.approve(approved, TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), approved);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

        assertEq(logs[0].topics[0], keccak256("Approval(address,address,uint256)"));
        address _owner = abi.decode(abi.encodePacked(logs[0].topics[1]), (address));
        address _approved = abi.decode(abi.encodePacked(logs[0].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[0].topics[3]), (uint256));
        assertEq(_owner, owner);
        assertEq(_approved, approved);
        assertEq(_tokenId, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approve to current owner
    function testApproveToOwner() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: approval to current owner");
        erc3525.approve(owner, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approve  but sender is not the owner
    function testApproveSenderNotOwn() public {
        vm.startPrank(other);
        vm.recordLogs();

        vm.expectRevert("ERC3525: approve caller is not owner nor approved for all");
        erc3525.approve(approved, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approved address approve to other again
    function testSecondHandRose() public {
        vm.startPrank(owner);
        vm.recordLogs();

        erc3525.approve(approved, TOKEN_ID_1);
        vm.stopPrank();
        vm.startPrank(approved);

        vm.expectRevert("ERC3525: approve caller is not owner nor approved for all");
        erc3525.approve(other, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approve when sender is the operator
    function testApproveWhenOperator() public {
        vm.startPrank(owner);
        erc3525.setApprovalForAll(operator, true);
        vm.stopPrank();

        vm.recordLogs();
        vm.startPrank(operator);
        erc3525.approve(approved, TOKEN_ID_1);
        assertEq(erc3525.getApproved(TOKEN_ID_1), approved);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

        assertEq(logs[0].topics[0], keccak256("Approval(address,address,uint256)"));
        address _owner = abi.decode(abi.encodePacked(logs[0].topics[1]), (address));
        address _approved = abi.decode(abi.encodePacked(logs[0].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[0].topics[3]), (uint256));
        assertEq(_owner, owner);
        assertEq(_approved, approved);
        assertEq(_tokenId, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test approved by nonexistent token id
    function testApproveNoneExistTokenId() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.approve(approved, nonExistentTokenId);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test setApprovalForAll
    function testSetApprovalForAll() public {
        vm.startPrank(owner);
        vm.recordLogs();

        erc3525.setApprovalForAll(operator, true);
        assertEq(erc3525.isApprovedForAll(owner, operator), true);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

        assertEq(logs[0].topics[0], keccak256("ApprovalForAll(address,address,bool)"));
        address _owner = abi.decode(abi.encodePacked(logs[0].topics[1]), (address));
        address _operator = abi.decode(abi.encodePacked(logs[0].topics[2]), (address));
        assertEq(_owner, owner);
        assertEq(_operator, operator);

        erc3525.setApprovalForAll(operator, false);
        assertEq(erc3525.isApprovedForAll(owner, operator), false);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test setApprovalForAll when sender is the operator
    function testSetApprovalForAllWhenSenderIsOperator() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: approve to caller");
        erc3525.setApprovalForAll(owner, true);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test getApproved
    function testGetApproved() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.getApproved(nonExistentTokenId);

        address _approved = erc3525.getApproved(TOKEN_ID_1);
        assertEq(_approved, approved);

        _approved = erc3525.getApproved(TOKEN_ID_2);
        assertEq(_approved, address(0));

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test mint
    function testMint() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: mint to the zero address");
        erc3525.mint(address(0), TOKEN_ID_3, 1, 0);
        assertEq(erc3525.ownerOf(TOKEN_ID_1), owner);

        vm.expectRevert("ERC3525: token already minted");
        erc3525.mint(owner, TOKEN_ID_1, 1, 0);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test burn
    function testBurn() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.burn(nonExistentTokenId);

        erc3525.burn(TOKEN_ID_1);
        assertEq(erc3525.balanceOf(owner), 1);

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.ownerOf(TOKEN_ID_1);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 3);

        // event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        assertEq(logs[2].topics[0], keccak256("Transfer(address,address,uint256)"));

        address _from = abi.decode(abi.encodePacked(logs[2].topics[1]), (address));
        address _to = abi.decode(abi.encodePacked(logs[2].topics[2]), (address));
        uint256 _tokenId = abi.decode(abi.encodePacked(logs[2].topics[3]), (uint256));
        assertEq(_from, owner);
        assertEq(_to, address(0));
        assertEq(_tokenId, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test ERC721 Enumerable behavior
    // ------------------------------------------------------
    // test ERC721Enumerable
    function testERC721Enumerable() public {
        vm.startPrank(owner);
        vm.recordLogs();

        assertEq(erc3525.totalSupply(), 2);
        assertEq(erc3525.tokenOfOwnerByIndex(owner, 0), TOKEN_ID_1);

        vm.expectRevert("ERC3525: owner index out of bounds");
        erc3525.tokenOfOwnerByIndex(owner, 2);

        vm.expectRevert("ERC3525: owner index out of bounds");
        erc3525.tokenOfOwnerByIndex(other, 0);

        erc3525.transferFrom(owner, other, TOKEN_ID_1);
        erc3525.transferFrom(owner, other, TOKEN_ID_2);
        assertEq(erc3525.tokenOfOwnerByIndex(other, 0), TOKEN_ID_1);
        assertEq(erc3525.tokenOfOwnerByIndex(other, 1), TOKEN_ID_2);

        assertEq(erc3525.balanceOf(owner), 0);
        vm.expectRevert("ERC3525: owner index out of bounds");
        erc3525.tokenOfOwnerByIndex(owner, 0);

        vm.expectRevert("ERC3525: global index out of bounds");
        erc3525.tokenByIndex(2);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test ERC721Enumerable tokenByIndex
    function testERC721EnumerableTokenByIndex() public {
        vm.startPrank(owner);
        vm.recordLogs();

        erc3525.burn(TOKEN_ID_1);
        erc3525.mint(owner, 300, 0, 0);
        erc3525.mint(owner, 400, 0, 0);
        assertEq(erc3525.totalSupply(), 3);

        uint256 index1 = erc3525.tokenByIndex(0);
        uint256 index2 = erc3525.tokenByIndex(1);
        uint256 index3 = erc3525.tokenByIndex(2);
        assertEq(index1, TOKEN_ID_2);
        assertEq(index2, 300);
        assertEq(index3, 400);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test ERC721Enumerable mint
    function testERC721EnumerableMint() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: mint to the zero address");
        erc3525.mint(address(0), 300, 0, 0);

        uint256 index1 = erc3525.tokenByIndex(0);
        assertEq(index1, TOKEN_ID_1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // test ERC721Enumerable burn
    function testERC721EnumerableBurn() public {
        vm.startPrank(owner);
        vm.recordLogs();

        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.burn(nonExistentTokenId);
        
        erc3525.burn(TOKEN_ID_1);
        assertEq(erc3525.balanceOf(owner), 1);
        assertEq(erc3525.totalSupply(), 1);
        assertEq(erc3525.tokenOfOwnerByIndex(owner, 0), TOKEN_ID_2);
        erc3525.burn(TOKEN_ID_2);
        assertEq(erc3525.totalSupply(), 0);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test ERC721 Metadata behavior
    // ------------------------------------------------------

    // test ERC721Enumerable burn
    function testERC721Metadata() public {
        vm.startPrank(owner);
        vm.recordLogs();

        assertEq(erc3525.name(), name);
        assertEq(erc3525.symbol(), symbol);
        assertEq(erc3525.tokenURI(TOKEN_ID_1), '');
        // well , we need set the baseURI to test this
        
        vm.expectRevert("ERC3525: invalid token ID");
        erc3525.tokenURI(nonExistentTokenId);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }
}