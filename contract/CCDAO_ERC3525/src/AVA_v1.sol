// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC3525SlotEnumerable.sol";

contract AVA_v1 is Context, Ownable, ERC3525SlotEnumerable {
    // Base URI for computing {tokenURI} and {slotURI}
    string private _avaURI;

    // Mapping for token-specific URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mapping for slot-specific URIs
    mapping(uint256 => string) private _slotURIs;

    uint256 private _maxTotalValue;

    uint256 private _minTransferValue;

    uint256 private _currentTotalValue;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory baseURI_,
        uint256 maxTotalValue_,
        uint256 minTransferValue_
    ) ERC3525SlotEnumerable(name_, symbol_, decimals_) Ownable(msg.sender) {
        require(
            minTransferValue_ > 0,
            "AVA_v1: min transfer value must be positive"
        );
        require(
            maxTotalValue_ % minTransferValue_ == 0,
            "AVA_v1: max total value must be divisible by min transfer value"
        );

        _avaURI = baseURI_;
        _maxTotalValue = maxTotalValue_;
        _minTransferValue = minTransferValue_;
        _currentTotalValue = 0;

        // Initialize the token ID generator，默认初次发售不超过10000个token
        _tokenIdGenerator = 10000;
    }

    // -------------------------------
    // limit query
    // -------------------------------
    function maxTotalValue() public view returns (uint256) {
        return _maxTotalValue;
    }

    function minTransferValue() public view returns (uint256) {
        return _minTransferValue;
    }

    function currentTotalValue() public view returns (uint256) {
        return _currentTotalValue;
    }

    // -------------------------------
    // URI Management
    // -------------------------------
    function _baseURI() internal view override returns (string memory) {
        return _avaURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _avaURI = baseURI_;
    }

    // -------------------------------
    // Minting and Burning
    // -------------------------------

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 slot_,
        uint256 value_
    ) public onlyOwner {
        require(
            _currentTotalValue + value_ <= _maxTotalValue,
            "AVA_v1: exceeds max total value"
        );

        require(
            value_ % _minTransferValue == 0,
            "AVA_v1: value must be a multiple of min transfer value"
        );

        _mint(to_, tokenId_, slot_, value_);
        _currentTotalValue += value_;
    }

    function mintValue(uint256 tokenId_, uint256 value_) public onlyOwner {
        require(
            _currentTotalValue + value_ <= _maxTotalValue,
            "AVA_v1: exceeds max total value"
        );

        require(
            value_ % _minTransferValue == 0,
            "AVA_v1: value must be a multiple of min transfer value"
        );

        _mintValue(tokenId_, value_);
        _currentTotalValue += value_;
    }

    function burn(uint256 tokenId_) public onlyOwner {
        uint256 value = balanceOf(tokenId_);
        _burn(tokenId_);
        _currentTotalValue -= value;
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public onlyOwner {
        // 检查burnValue是否为最小转账单位的整数倍
        require(
            burnValue_ % _minTransferValue == 0,
            "AVA_v1: burn value must be a multiple of min transfer value"
        );

        _burnValue(tokenId_, burnValue_);
        _currentTotalValue -= burnValue_;
    }

    /**
     * @dev Override the transferFrom method of ERC3525 to ensure the transferred value complies with the minimum unit
     */
    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable override(ERC3525, IERC3525) {
        require(
            value_ % _minTransferValue == 0,
            "AVA_v1: transfer value must be a multiple of min transfer value"
        );

        super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    /**
     * @dev Override the transferFrom method of ERC3525 to ensure the transferred value complies with the minimum unit
     */
    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable override(ERC3525, IERC3525) returns (uint256) {
        require(
            value_ % _minTransferValue == 0,
            "AVA_v1: transfer value must be a multiple of min transfer value"
        );

        return super.transferFrom(fromTokenId_, to_, value_);
    }
}
