// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./CallsStructs.sol";

interface ICalls {
  function call(
    CallsStructs.CallRequest calldata _callRequest,
    bytes[] calldata _signatures
  ) external returns (bytes memory);

  function multiCall(
    CallsStructs.CallRequest[] calldata _callRequests,
    bytes[] calldata _signatures
  ) external returns (bytes[] memory);
}