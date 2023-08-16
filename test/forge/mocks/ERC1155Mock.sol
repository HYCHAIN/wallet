// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title ERC1155MockDecimals
/// @dev ONLY FOR TESTS
contract ERC1155Mock is ERC1155 {
    constructor() ERC1155("www.example.come") { }

    /// @dev Mint _amount to _to.
    /// @param _to The address that will receive the mint
    /// @param _amount The amount to be minted
    function mint(address _to, uint256 _tokenId, uint256 _amount) external {
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev needed to reference function selector as ERC1155Mock.safeTransferFrom.selector
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev needed to reference function selector as ERC1155Mock.safeBatchTransferFrom.selector
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /**
     * @dev needed to reference function selector as ERC1155Mock.setApprovalForAll.selector
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        super.setApprovalForAll(operator, approved);
    }
}
