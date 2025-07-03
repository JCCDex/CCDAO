// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CCDAO_ERC721} from "../src/CCDAO_ERC721.sol";

interface ICommunityVerifier {
    function setReturnTrue() external;
    function setReturnFalse() external;
    function isVerifiedMember(address user) external view returns (bool);
}

contract MockCommunityVerifier {

    bool public isMember;

    function setReturnTrue() external {
        isMember = true;
    }
    function setReturnFalse() external {
        isMember = false;
    }

    function isVerifiedMember(address user) external view returns (bool) {
        user;
        return isMember;
    }
}

contract CCDAO_ERC721Test is Test {
    CCDAO_ERC721 private erc721;

    address private owner = vm.addr(1);
    address private user1 = vm.addr(2);
    address private user2 = vm.addr(3);
    address private user3 = vm.addr(4);
    MockCommunityVerifier private communityVerifier = new MockCommunityVerifier();

    uint256 snapshotId;

    function setUp() public {
        vm.startPrank(owner);
        erc721 = new CCDAO_ERC721();
        vm.stopPrank();

        snapshotId = vm.snapshotState();
    }

    function testName() public view {
        assertEq(erc721.name(), "Cross Chain DAO NFT");
    }

    function testMint() public {
        vm.startPrank(owner);
        erc721.mint(user1);
        vm.stopPrank();

        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.ownerOf(0), user1);

        vm.revertToState(snapshotId);
    }

    function testMintByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        erc721.mint(user1);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testMintByCCDAOMember() public {
        vm.startPrank(user1);
        communityVerifier.setReturnTrue();
        vm.expectRevert("Community verifier not set");
        erc721.mintWithCommunityVerification(user1);
        vm.stopPrank();

        vm.startPrank(owner);
        erc721.setCommunityVerifier(address(communityVerifier));
        vm.stopPrank();

        vm.startPrank(user1);
        erc721.mintWithCommunityVerification(user1);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.ownerOf(0), user1);

        vm.expectRevert("Already minted with community verification");
        erc721.mintWithCommunityVerification(user1);
        vm.stopPrank();


        vm.revertToState(snapshotId);
    }

    function testTokenURI() public {
        vm.startPrank(owner);
        erc721.mint(user1);
        vm.stopPrank();

        assertEq(erc721.tokenURI(0), "");

        vm.startPrank(owner);
        // erc721.setBaseURI("ipfs://QmExample/");
        erc721.setBaseURI("ipfs://bafybeigdoc4pdukx2bupifreiphef7wmrbynjnqwvu3nnkaowuxsxwb43q/");
        assertEq(erc721.tokenURI(0), "ipfs://bafybeigdoc4pdukx2bupifreiphef7wmrbynjnqwvu3nnkaowuxsxwb43q/0");
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    // ======== Enumerable 功能测试 ========

    function testTotalSupply() public {
        assertEq(erc721.totalSupply(), 0);

        vm.startPrank(owner);
        erc721.mint(user1);
        erc721.mint(user1);
        erc721.mint(user2);
        vm.stopPrank();

        assertEq(erc721.totalSupply(), 3);

        vm.revertToState(snapshotId);
    }

    function testTokenByIndex() public {
        vm.startPrank(owner);
        erc721.mint(user1); // tokenId: 0
        erc721.mint(user2); // tokenId: 1
        erc721.mint(user3); // tokenId: 2
        vm.stopPrank();

        assertEq(erc721.tokenByIndex(0), 0);
        assertEq(erc721.tokenByIndex(1), 1);
        assertEq(erc721.tokenByIndex(2), 2);

        vm.revertToState(snapshotId);
    }

    function testTokenByIndexOutOfBounds() public {
        vm.startPrank(owner);
        erc721.mint(user1);
        vm.stopPrank();

        // 尝试访问超出范围的索引
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC721OutOfBoundsIndex(address,uint256)",
                address(0),
                1
            )
        );
        erc721.tokenByIndex(1);

        vm.revertToState(snapshotId);
    }

    function testTokenOfOwnerByIndex() public {
        vm.startPrank(owner);
        erc721.mint(user1); // tokenId: 0
        erc721.mint(user1); // tokenId: 1
        erc721.mint(user2); // tokenId: 2
        vm.stopPrank();

        assertEq(erc721.tokenOfOwnerByIndex(user1, 0), 0);
        assertEq(erc721.tokenOfOwnerByIndex(user1, 1), 1);
        assertEq(erc721.tokenOfOwnerByIndex(user2, 0), 2);

        vm.revertToState(snapshotId);
    }

    function testTokenOfOwnerByIndexOutOfBounds() public {
        vm.startPrank(owner);
        erc721.mint(user1);
        vm.stopPrank();

        // 尝试访问超出用户持有范围的索引
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC721OutOfBoundsIndex(address,uint256)",
                user1,
                1
            )
        );
        erc721.tokenOfOwnerByIndex(user1, 1);

        vm.revertToState(snapshotId);
    }

    // ======== 转账后枚举测试 ========

    function testEnumerableAfterTransfer() public {
        vm.startPrank(owner);
        erc721.mint(user1); // tokenId: 0
        erc721.mint(user1); // tokenId: 1
        erc721.mint(user1); // tokenId: 2
        vm.stopPrank();

        vm.startPrank(user1);
        erc721.transferFrom(user1, user2, 1);
        vm.stopPrank();

        // 检查转账后的状态
        assertEq(erc721.balanceOf(user1), 2);
        assertEq(erc721.balanceOf(user2), 1);

        // 检查user1的代币
        assertEq(erc721.tokenOfOwnerByIndex(user1, 0), 0);
        assertEq(erc721.tokenOfOwnerByIndex(user1, 1), 2);

        // 检查user2的代币
        assertEq(erc721.tokenOfOwnerByIndex(user2, 0), 1);

        vm.revertToState(snapshotId);
    }

    // ======== 批量操作测试 ========

    function testBatchMintAndEnumerate() public {
        vm.startPrank(owner);

        // 批量铸造10个NFT
        for (uint i = 0; i < 10; i++) {
            erc721.mint(user1);
        }
        vm.stopPrank();

        // 验证总供应量
        assertEq(erc721.totalSupply(), 10);
        assertEq(erc721.balanceOf(user1), 10);

        // 验证所有代币都可以通过全局索引访问
        for (uint i = 0; i < 10; i++) {
            assertEq(erc721.tokenByIndex(i), i);
        }

        // 验证所有代币都可以通过所有者索引访问
        for (uint i = 0; i < 10; i++) {
            assertEq(erc721.tokenOfOwnerByIndex(user1, i), i);
        }

        vm.revertToState(snapshotId);
    }

    // ======== 最大供应量测试 ========

    function testMaxSupply() public {
        vm.startPrank(owner);

        // 铸造接近但不超过MAX_SUPPLY的代币
        uint256 testLimit = 20; // 实际测试中改小，避免测试用例过大
        for (uint i = 0; i < testLimit; i++) {
            erc721.mint(user1);
        }

        // 检查供应量
        assertEq(erc721.totalSupply(), testLimit);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testMintExceedMaxSupply() public {
        vm.startPrank(owner);
        erc721.mint(user1);

        // 模拟已接近最大供应量
        uint256 presetTokens = erc721.MAX_SUPPLY() - 1;
        // 这个循环是一个探针程序，寻找定位_nextTokenId变量的存储位置
        // for (uint i = 0; i < 20; i++) {
        //     bytes32 value = vm.load(address(erc721), bytes32(i));
        //     console.log("Storage slot", i, ":");
        //     console.logBytes32(value);
        //     console.log(uint256(value));
        // }

        uint256 slot = 11;
        vm.store(address(erc721), bytes32(slot), bytes32(presetTokens));

        // 铸造最后一个代币应该成功
        erc721.mint(user1);

        // 再铸造应该失败
        vm.expectRevert("Max supply reached");
        erc721.mint(user1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }
}
