// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./PreauthorizedCallsStructs.sol";

library PreauthorizedCallsStorage {
  bytes32 private constant STORAGE_SLOT = keccak256("com.trymetafab.wallet.PreauthorizedCalls");

  struct Layout {
    mapping(bytes32 => PreauthorizedCallsStructs.CallRequestPreauthorization) callRequestPreauthorizations;
  }

  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;

    assembly {
      _layout.slot := slot
    }
  }
}