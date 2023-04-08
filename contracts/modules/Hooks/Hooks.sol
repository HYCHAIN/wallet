// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "../../interfaces/receivers/IERC721Receiver.sol";
import "../../interfaces/receivers/IERC1155Receiver.sol";

contract Hooks is IERC1155Receiver, IERC721Receiver {
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns (bytes4) {
    return Hooks.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address,address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns (bytes4) {
    return Hooks.onERC1155BatchReceived.selector;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
    return Hooks.onERC721Received.selector;
  }

  receive() external payable { }
}