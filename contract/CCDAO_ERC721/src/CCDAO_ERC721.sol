// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CCDAO_ERC721 is ERC721, Ownable {
    
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    constructor() ERC721("Cross Chain DAO NFT", "CCDAO") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner {
        require(_nextTokenId < MAX_SUPPLY, "Max supply reached");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
