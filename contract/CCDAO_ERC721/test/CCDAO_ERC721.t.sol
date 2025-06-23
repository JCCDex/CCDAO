// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CCDAO_ERC721} from "../src/CCDAO_ERC721.sol";

contract CCDAO_ERC721Test is Test {
    CCDAO_ERC721 private erc721;

    address private owner = vm.addr(1);
    address private user = vm.addr(2);

    uint256 snapshotId;

    function setUp() public {
        vm.startPrank(owner);
        erc721 = new CCDAO_ERC721();
        vm.stopPrank();

        snapshotId = vm.snapshot();
    }

    function testName() public view {
        assertEq(erc721.name(), "Cross Chain DAO NFT");
    }

    function testMint() public {
        vm.startPrank(owner);
        erc721.mint(user);
        vm.stopPrank();

        assertEq(erc721.balanceOf(user), 1);
        assertEq(erc721.ownerOf(0), user);

        vm.revertToState(snapshotId);
    }

    function testMintByNonOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        erc721.mint(user);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testTokenURI() public {
        vm.startPrank(owner);
        erc721.mint(user);
        vm.stopPrank();

        assertEq(erc721.tokenURI(0), "");

        vm.startPrank(owner);
        erc721.setBaseURI("https://ccda.ooo/nft/");
        assertEq(erc721.tokenURI(0), "https://ccda.ooo/nft/0");
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }
}
