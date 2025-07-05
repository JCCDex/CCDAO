// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, Vm, console} from "forge-std/Test.sol";
import "../src/AVA_v1.sol";
// import "../src/mocks/ERC3525BaseMock.sol";
// import {ERC3525ReceiverMock} from "../src/mocks/ERC3525ReceiverMock.sol";
// import "../src/mocks/NonReceiverMock.sol";

/**
  1. 设置修改baseURI以及权限，主要是空白基金合同模板，metadataURI的URI可以合约合成 done
  2. 管理员权限: 铸造非0value的token, 销毁token, 修改baseURI, 黑名单管理
  3. 基金初始资产规模上限控制，基金客户数量控制: 按照最大初始资产除以最小交易单位算出最大客户数量 done
 */
contract AVA_v1Test is Test {
    AVA_v1 private ava001;

    uint256 private constant firstSlot = 1;
    uint256 private constant secondSlot = 2;
    uint256 private constant nonExistentSlot = 99;

    uint256 private constant firstTokenId = 1;
    uint256 private constant secondTokenId = 2;
    uint256 private constant thirdTokenId = 3;
    uint256 private constant fourthTokenId = 4;
    uint256 private constant nonExistentTokenId = 9901;

    uint256 private constant firstTokenValue = 100000e18;
    uint256 private constant secondTokenValue = 200000e18;
    uint256 private constant thirdTokenValue = 300000e18;
    uint256 private constant fourthTokenValue = 400000e18;
    
    uint256 private constant maxTotalValue = 2000000e18;
    uint256 private constant minTransferValue = 100000e18;

    // TODO:等确定ERC3525ReceiverMock的实现后再修改
    // bytes4 RECEIVER_MAGIC_VALUE = 0x009ce20b;

    address private admin = vm.addr(1);
    address private firstOwner = vm.addr(2);
    address private secondOwner = vm.addr(3);
    // address private newOwner = vm.addr(4);
    address private approved = vm.addr(4);
    // address private valueApproved = vm.addr(5);
    // address private anotherApproved = vm.addr(6);
    address private operator = vm.addr(7);
    // address private slotOperator = vm.addr(8);
    address private other = vm.addr(9);
    address private other2 = vm.addr(10);
    address private toWhom;

    string name = 'Australia Valued Assets 001';
    string symbol = 'AVA001';
    uint8 decimals = 18;
    string baseURI = 'https://avat.shop/ava/001/';

    uint256 snapshotId; 

    function setUp() public {
        vm.startPrank(admin);
        ava001 = new AVA_v1(name, symbol, decimals, baseURI, maxTotalValue, minTransferValue);
        // erc3525ReceiverMock = new ERC3525ReceiverMock(RECEIVER_MAGIC_VALUE, ERC3525ReceiverMock.Error.None);
        // nonReceiverMock = new NonReceiverMock();

        ava001.mint(firstOwner, firstTokenId, firstSlot, firstTokenValue);
        ava001.mint(secondOwner, secondTokenId, firstSlot, secondTokenValue);

        vm.stopPrank();

        vm.startPrank(firstOwner);
        ava001.approve(approved, firstTokenId);
        ava001.setApprovalForAll(operator, true);

        vm.stopPrank();
        snapshotId = vm.snapshotState();
    }

    // ------------------------------------------------------
    // test AVA behavior
    // ------------------------------------------------------    
    function testOwnership() public {
        // Check initial owner
        assertEq(ava001.owner(), admin);

        // Check transfer ownership
        vm.startPrank(admin);
        ava001.transferOwnership(other);
        vm.stopPrank();
        assertEq(ava001.owner(), other);

        // Check renounce ownership
        vm.startPrank(other);
        ava001.renounceOwnership();
        vm.stopPrank();
        assertEq(ava001.owner(), address(0));

        vm.revertToState(snapshotId);
    }

    function testMetaData() public {
        // Check initial owner
        assertEq(ava001.owner(), admin);
        string memory contractURI = ava001.contractURI();
        // 此处映射到IPFS网络中的基金模板合同，显示的内容根据持有的通证数据进行合成
        assertEq(contractURI, "https://avat.shop/ava/001/contract/0xf2e246bb76df876cef8b38ae84130f4f55de395b");
        // 映射返回这个插槽的概况，所有的token数量，简短的描述，在AVA001中没啥作用，固定为1，固定存放AVA001基金通证
        assertEq(ava001.slotURI(firstSlot), "https://avat.shop/ava/001/slot/1");
        // 映射返回这个通证的概况，持有人，基金数量，基金描述，以及基金的图片，模板内容存放在IPFS网络中，数据来自链上
        assertEq(ava001.tokenURI(firstTokenId), "https://avat.shop/ava/001/1");
        assertEq(ava001.tokenURI(secondTokenId), "https://avat.shop/ava/001/2");

        vm.startPrank(admin);
        ava001.setBaseURI("https://avat.au/ava/001/");
        contractURI = ava001.contractURI();
        assertEq(contractURI, "https://avat.au/ava/001/contract/0xf2e246bb76df876cef8b38ae84130f4f55de395b");
        vm.stopPrank();

        // TODO: 测试非管理员修改baseURI
        vm.startPrank(firstOwner);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            firstOwner
        ));
        ava001.setBaseURI("https://avat.au/ava/001/");
        vm.stopPrank();
        
        vm.revertToState(snapshotId);
    }

    function testBalanceOf() public {

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 1);
        assertEq(ava001.balanceOf(secondOwner), 1);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), firstTokenValue);
        assertEq(ava001.balanceOf(secondTokenId), secondTokenValue);

        // --------------------------------------------
        // Check balance after transfer value
        vm.startPrank(firstOwner);
        ava001.transferFrom(firstTokenId, secondTokenId, firstTokenValue);
        vm.stopPrank();

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 1);
        assertEq(ava001.balanceOf(secondOwner), 1);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), 0);
        assertEq(ava001.balanceOf(secondTokenId), secondTokenValue + firstTokenValue);
        // --------------------------------------------
        // Check balance after transfer token
        vm.startPrank(firstOwner);
        ava001.transferFrom(firstOwner, secondOwner, firstTokenId);
        vm.stopPrank();

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 0);
        assertEq(ava001.balanceOf(secondOwner), 2);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), 0);
        assertEq(ava001.balanceOf(secondTokenId), secondTokenValue + firstTokenValue);
        // --------------------------------------------

        vm.expectRevert("ERC3525: invalid token ID");
        ava001.balanceOf(0);

        vm.expectRevert("ERC3525: invalid token ID");
        ava001.balanceOf(nonExistentTokenId);

        vm.revertToState(snapshotId);
    }

    function testTransferFrom() public {
        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 1);
        assertEq(ava001.balanceOf(secondOwner), 1);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), firstTokenValue);
        assertEq(ava001.balanceOf(secondTokenId), secondTokenValue);

        // --------------------------------------------
        // Check transfer value to new account twice
        vm.startPrank(secondOwner);
        assertEq(ava001.totalSupply(), 2);
        uint256 fromOwnerBalance = ava001.balanceOf(secondOwner);
        uint256 fromTokenValue = ava001.balanceOf(secondTokenId);
        uint256 toOwnerBalance = ava001.balanceOf(other);

        // 业务意义: 一个基金持有者向另一个基金持有者转账部分基金份额，对方没有相同基金时候需要在转账同事铸造一个新的token
        ava001.transferFrom(secondTokenId, other, minTransferValue);
        
        // 总的token供应量加1
        assertEq(ava001.totalSupply(), 3);
        // 转账的源账号持有的token(基金合同)数量不变
        assertEq(ava001.balanceOf(secondOwner), fromOwnerBalance);
        // 转账的源账号持有的token（基金）对应的资产份额减少
        assertEq(ava001.balanceOf(secondTokenId), fromTokenValue - minTransferValue);
        // 目的地账号持有的基金合同加1，等于多了一份基金合同，对应铸造了一个新的token
        uint256 toTokenId = ava001.tokenOfOwnerByIndex(other, toOwnerBalance);
        // 目的地账号持有的token（基金）对应的资产份额等于转账的资产份额
        assertEq(ava001.balanceOf(toTokenId), minTransferValue);
        // 目的地账号持有的token加1，相当于多了一份基金合同
        assertEq(ava001.balanceOf(other), 1);
        assertEq(toTokenId, 10000);

        ava001.transferFrom(secondTokenId, other, minTransferValue);

        assertEq(ava001.totalSupply(), 4);
        assertEq(ava001.balanceOf(secondOwner), fromOwnerBalance);
        assertEq(ava001.balanceOf(secondTokenId), fromTokenValue - 2 * minTransferValue);
        // 目的地账号已经持有这个基金合同了，因此tokenId(合同编号)不变,变化的是对应的资产份额
        toTokenId = ava001.tokenOfOwnerByIndex(other, toOwnerBalance);
        assertEq(ava001.balanceOf(toTokenId), minTransferValue);
        assertEq(ava001.balanceOf(other), 2);
        assertEq(toTokenId, 10000);

        vm.stopPrank();

        vm.revertToState(snapshotId);

        // --------------------------------------------
        // Check transfer value to new two accounts
        vm.startPrank(secondOwner);
        assertEq(ava001.totalSupply(), 2);
        fromOwnerBalance = ava001.balanceOf(secondOwner);
        fromTokenValue = ava001.balanceOf(secondTokenId);
        toOwnerBalance = ava001.balanceOf(other);

        // 业务意义: 一个基金持有者向另一个基金持有者转账部分基金份额，对方没有相同基金时候需要在转账同事铸造一个新的token
        ava001.transferFrom(secondTokenId, other, minTransferValue);
        
        // 总的token供应量加1
        assertEq(ava001.totalSupply(), 3);
        // 转账的源账号持有的token(基金合同)数量不变
        assertEq(ava001.balanceOf(secondOwner), fromOwnerBalance);
        // 转账的源账号持有的token（基金）对应的资产份额减少
        assertEq(ava001.balanceOf(secondTokenId), fromTokenValue - minTransferValue);
        // 目的地账号持有的基金合同加1，等于多了一份基金合同，对应铸造了一个新的token
        toTokenId = ava001.tokenOfOwnerByIndex(other, toOwnerBalance);
        // 目的地账号持有的token（基金）对应的资产份额等于转账的资产份额
        assertEq(ava001.balanceOf(toTokenId), minTransferValue);
        // 目的地账号持有的token加1，相当于多了一份基金合同
        assertEq(ava001.balanceOf(other), 1);
        assertEq(toTokenId, 10000);

        toOwnerBalance = ava001.balanceOf(other2);
        ava001.transferFrom(secondTokenId, other2, minTransferValue);

        assertEq(ava001.totalSupply(), 4);
        assertEq(ava001.balanceOf(secondOwner), fromOwnerBalance);
        assertEq(ava001.balanceOf(secondTokenId), fromTokenValue - 2 * minTransferValue);
        toTokenId = ava001.tokenOfOwnerByIndex(other2, toOwnerBalance);
        assertEq(ava001.balanceOf(toTokenId), minTransferValue);
        assertEq(ava001.balanceOf(other2), 1);
        // 转给两个新用户，合同编号也自动加了两份
        assertEq(toTokenId, 10001);

        vm.stopPrank();

        vm.revertToState(snapshotId);

        // --------------------------------------------
        // Check transfer value to new two accounts and mint 10001 tokenId first
        vm.startPrank(admin);
        ava001.mint(firstOwner, 10001, firstSlot, firstTokenValue);
        vm.stopPrank();

        vm.startPrank(secondOwner);
        assertEq(ava001.totalSupply(), 3);
        fromOwnerBalance = ava001.balanceOf(secondOwner);
        fromTokenValue = ava001.balanceOf(secondTokenId);
        toOwnerBalance = ava001.balanceOf(other);

        // 业务意义: 一个基金持有者向另一个基金持有者转账部分基金份额，对方没有相同基金时候需要在转账同事铸造一个新的token
        ava001.transferFrom(secondTokenId, other, minTransferValue);
        
        // 总的token供应量加1
        assertEq(ava001.totalSupply(), 4);
        // 转账的源账号持有的token(基金合同)数量不变
        assertEq(ava001.balanceOf(secondOwner), fromOwnerBalance);
        // 转账的源账号持有的token（基金）对应的资产份额减少
        assertEq(ava001.balanceOf(secondTokenId), fromTokenValue - minTransferValue);
        // 目的地账号持有的基金合同加1，等于多了一份基金合同，对应铸造了一个新的token
        toTokenId = ava001.tokenOfOwnerByIndex(other, toOwnerBalance);
        // 目的地账号持有的token（基金）对应的资产份额等于转账的资产份额
        assertEq(ava001.balanceOf(toTokenId), minTransferValue);
        // 目的地账号持有的token加1，相当于多了一份基金合同
        assertEq(ava001.balanceOf(other), 1);
        assertEq(toTokenId, 10000);

        toOwnerBalance = ava001.balanceOf(other2);
        vm.expectRevert("ERC3525: token already minted");
        ava001.transferFrom(secondTokenId, other2, minTransferValue);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test AVA minting
    // ------------------------------------------------------    
    function testMinting() public {
        // --------------------------------------------
        // Check minting
        vm.startPrank(admin);
        ava001.mint(firstOwner, thirdTokenId, firstSlot, thirdTokenValue);

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 2);
        assertEq(ava001.balanceOf(secondOwner), 1);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(thirdTokenId), thirdTokenValue);
        assertEq(ava001.balanceOf(firstTokenId), firstTokenValue);
        assertEq(ava001.balanceOf(secondTokenId), secondTokenValue);

        // --------------------------------------------
        // allow minting with zero value
        ava001.mint(firstOwner, fourthTokenId, firstSlot, 0);
        assertEq(ava001.balanceOf(fourthTokenId), 0);

        // mint duplicated tokenId
        vm.expectRevert("ERC3525: token already minted");
        ava001.mint(firstOwner, firstTokenId, firstSlot, firstTokenValue);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testMintingNonOwner() public {
        // --------------------------------------------
        // checck minting by non-owner
        vm.startPrank(firstOwner);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            firstOwner
        ));
        ava001.mint(firstOwner, thirdTokenId, firstSlot, thirdTokenValue);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testMintingValue() public {
        // --------------------------------------------
        // Check minting
        vm.startPrank(admin);
        assertEq(ava001.balanceOf(firstOwner), 1);
        assertEq(ava001.balanceOf(firstTokenId), firstTokenValue);

        ava001.mintValue(firstTokenId, firstTokenValue);

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 1);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), firstTokenValue + firstTokenValue);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testMintingValueNonOwner() public {
        // --------------------------------------------
        // checck minting value by non-owner
        vm.startPrank(firstOwner);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            firstOwner
        ));
        ava001.mintValue(firstTokenId, 100000);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test AVA burning
    // ------------------------------------------------------    
    function testBurning() public {
        // --------------------------------------------
        // Check minting
        vm.startPrank(admin);
        ava001.mint(firstOwner, thirdTokenId, firstSlot, thirdTokenValue);
        ava001.burnValue(firstTokenId, firstTokenValue);

        // Check NFT token balance of owner
        assertEq(ava001.balanceOf(firstOwner), 2);
        
        // Check value balance of owner's tokenId
        assertEq(ava001.balanceOf(firstTokenId), 0);

        ava001.burn(thirdTokenId);
        assertEq(ava001.balanceOf(firstOwner), 1);

        vm.expectRevert("ERC3525: invalid token ID");
        ava001.balanceOf(thirdTokenId);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testBurningNonOwner() public {
        // --------------------------------------------
        // Check minting
        vm.startPrank(admin);
        ava001.mint(firstOwner, thirdTokenId, firstSlot, thirdTokenValue);
        vm.stopPrank();

        vm.startPrank(firstOwner);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            firstOwner
        ));
        ava001.burnValue(firstTokenId, firstTokenValue);

        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            firstOwner
        ));
        ava001.burn(thirdTokenId);
        assertEq(ava001.balanceOf(firstOwner), 2);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test AVA001 limitations
    // ------------------------------------------------------ 
    function testLimitations() public {
        // Check max total value
        vm.startPrank(admin);
        ava001.mint(firstOwner, thirdTokenId, firstSlot, 1000000e18);
        vm.expectRevert("AVA_v1: exceeds max total value");
        ava001.mint(firstOwner, fourthTokenId, firstSlot, 2000000e18);

        // Check min transfer value
        vm.expectRevert("AVA_v1: value must be a multiple of min transfer value");
        ava001.mint(firstOwner, fourthTokenId, firstSlot, 99999e18);

        assertEq(ava001.currentTotalValue(), 1300000e18);
        ava001.mint(firstOwner, fourthTokenId, firstSlot, 700000e18);
        assertEq(ava001.currentTotalValue(), ava001.maxTotalValue());
        vm.stopPrank();

        vm.startPrank(firstOwner);
        ava001.transferFrom(thirdTokenId, secondTokenId, ava001.minTransferValue());
        assertEq(ava001.balanceOf(thirdTokenId), 1000000e18 - ava001.minTransferValue());

        vm.expectRevert("AVA_v1: transfer value must be a multiple of min transfer value");
        ava001.transferFrom(thirdTokenId, secondTokenId, 100001e18);
        vm.expectRevert("AVA_v1: transfer value must be a multiple of min transfer value");
        ava001.transferFrom(thirdTokenId, secondTokenId, 9999e18);
        vm.stopPrank();

        // 对于approve的数量不做限制，但是实际转账时必须是最小转账单位的整数倍
        vm.startPrank(approved);
        vm.expectRevert("AVA_v1: transfer value must be a multiple of min transfer value");
        ava001.transferFrom(firstTokenId, secondTokenId, 100001e18);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert("AVA_v1: transfer value must be a multiple of min transfer value");
        ava001.transferFrom(firstTokenId, secondTokenId, 9999e18);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ------------------------------------------------------
    // test AVA001 extra cases
    // ------------------------------------------------------ 
    function testExtraCase() public {
        vm.startPrank(secondOwner);
        ava001.transferFrom(secondTokenId, other, minTransferValue);
        ava001.transferFrom(secondTokenId, other2, minTransferValue);

        // 统计所有的tokenId
        uint256 _totalSupply = ava001.totalSupply();
        uint256[] memory tokenIds = new uint256[](_totalSupply);
        for (uint256 i = 0; i < _totalSupply; i++) {
            tokenIds[i] = ava001.tokenByIndex(i);
        }
        // 统计所有的tokenId对应的资产份额
        uint256 _totalTokenValue = ava001.totalSupply();
        uint256 _maxTotalValue = ava001.maxTotalValue();
        uint256 count = 0;
        assertEq(_totalTokenValue <= _maxTotalValue, true);
        for (uint256 i = 0; i < _totalSupply; i++) {
            if (ava001.balanceOf(tokenIds[i]) > 0) {
                count++;
            }
        }
        // 一共有4个tokenId ,但是非0value的tokenId只有3个
        assertEq(count, 3);
        assertEq(ava001.totalSupply(), 4);

        vm.stopPrank();

        vm.startPrank(admin);
        uint256 _beforeBurnBalance = ava001.balanceOf(other);
        uint256 _otherTokenId = ava001.tokenOfOwnerByIndex(other, 0);
        // 销毁2个token再统计
        ava001.burn(secondTokenId);
        ava001.burn(_otherTokenId);

        uint256 _afterBurnBalance = ava001.balanceOf(other);
        assertEq(_beforeBurnBalance - _afterBurnBalance, 1);

        // 先获得token总数，然后逐个获取tokenId
        _totalSupply = ava001.totalSupply();
        tokenIds = new uint256[](_totalSupply);
        for (uint256 i = 0; i < _totalSupply; i++) {
            tokenIds[i] = ava001.tokenByIndex(i);
        }
        // 统计所有的tokenId对应的资产份额
        _totalTokenValue = ava001.totalSupply();
        _maxTotalValue = ava001.maxTotalValue();
        count = 0;
        assertEq(_totalTokenValue <= _maxTotalValue, true);
        for (uint256 i = 0; i < _totalSupply; i++) {
            if (ava001.balanceOf(tokenIds[i]) > 0) {
                count++;
            }
        }
        // 一共有2个tokenId
        assertEq(count, 2);
        assertEq(ava001.totalSupply(), 2);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }
}