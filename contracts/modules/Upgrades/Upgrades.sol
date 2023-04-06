// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./IUpgrades.sol";
import "../Controllers/Controllers.sol";

contract Upgrades is IUpgrades, Controllers {
  bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function upgrade(
    address _implementation,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) 
    external
    meetsControllersThreshold(keccak256(abi.encode(_implementation, _nonce, block.chainid)), _signatures)
  {
    require(IUpgrades(_implementation).supportsUpgrades(), "Invalid implementation");
    
    assembly {
      sstore(address(), _implementation)
    }
  }

  function supportsUpgrades() external pure returns (bool) {
    return true;
  }
}