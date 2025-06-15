// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC3525.sol";

/**
 * @title AVA Semi-Fungible fund Token Standard
 */
interface IAVA is IERC3525 {
    function maxTotalValue() external view returns (uint256);
    function minTransferValue() external view returns (uint256);
    function currentTokenCount() external view returns (uint256);
    function currentTotalValue() external view returns (uint256);
    function setBaseURI(string calldata baseURI) external;
    function baseURI() external view returns (string memory);
    function mint(
        address to,
        uint256 tokenId,
        uint256 slot,
        uint256 value
    ) external;
    function mintValue(uint256 tokenId, uint256 value) external;
    function burn(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
