// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 社区认证接口
interface ICommunityVerifier {
    function isVerifiedMember(address user) external view returns (bool);
}

contract CCDAO_ERC721 is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _nextTokenId;
    string private _baseTokenURI;
    // 合约变量
    ICommunityVerifier public communityVerifier;
    mapping(address => bool) public hasMintedWithCommunity; // 记录已通过社区认证铸造的地址

    constructor() ERC721("Cross Chain DAO NFT", "CCDAO") Ownable(msg.sender) {}

    // 构造函数或设置函数中添加
    function setCommunityVerifier(address _verifier) external onlyOwner {
        communityVerifier = ICommunityVerifier(_verifier);
    }

    // 社区认证铸造方法
    function mintWithCommunityVerification(address to) external payable {
        require(address(communityVerifier) != address(0), "Community verifier not set");
        require(communityVerifier.isVerifiedMember(to), "Not a verified community member");
        require(!hasMintedWithCommunity[to], "Already minted with community verification");
        require(_nextTokenId < MAX_SUPPLY, "Max supply reached");
        
        uint256 tokenId = _nextTokenId++;
        hasMintedWithCommunity[to] = true; // 标记已铸造
        _safeMint(to, tokenId);
    }

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

    /**
     * @dev 重写_increaseBalance函数以解决继承冲突
     * ERC721Enumerable的实现会阻止批量操作
     */
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    /**
     * @dev 重写_update函数以支持枚举索引维护
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev 声明合约支持的接口
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
