// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "../Calls/ICalls.sol";
import "./PreauthorizedCallsStructs.sol";

interface IPreauthorizedCalls is ICalls {
  function preauthorizeCall(
    PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
    PreauthorizedCallsStructs.CallRequestPreauthorization calldata _callRequestPreauthorization,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function unauthorizeCall(
    PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function preauthorizedCall(
    CallsStructs.CallRequest calldata _callRequest
  ) external returns (bytes memory);

  function preauthorizedMultiCall(
    CallsStructs.CallRequest[] calldata _callRequests
  ) external returns (bytes[] memory);
}

