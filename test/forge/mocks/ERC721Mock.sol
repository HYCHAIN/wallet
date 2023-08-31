// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title ERC721MockDecimals
/// @dev ONLY FOR TESTS
contract ERC721Mock is ERC721 {
    constructor() ERC721("MOCKNAME", "MSYMBL") { }

    /**
     * @dev Mint the _tokenId to _to.
     * @param _to The address that will receive the mint
     * @param _tokenId The tokenId to be minted
     */
    function mint(address _to, uint256 _tokenId) external {
        _mint(_to, _tokenId);
    }

    /**
     * @dev needed to reference function selector as ERC721Mock.transferFrom.selector
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        super.transferFrom(from, to, id);
    }

    /**
     * @dev needed to reference function selector as ERC721Mock.setApprovalForAll.selector
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        super.setApprovalForAll(operator, approved);
    }
}
