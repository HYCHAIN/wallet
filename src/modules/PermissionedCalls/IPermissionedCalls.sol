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
import "./PermissionedCallsStructs.sol";

interface IPermissionedCalls is ICalls {
  function permitExecute(
    PermissionedCallsStructs.ExecuteRequestPermitted calldata _executeRequestPermitted,
    PermissionedCallsStructs.ExecuteRequestPermission calldata _executeRequestPermission,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function unpermitExecute(
    PermissionedCallsStructs.ExecuteRequestPermitted calldata _executeRequestPermitted,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function permittedExecute(
    CallsStructs.ExecuteRequest calldata _executeRequest
  ) external returns (bytes memory);

  function multiPermittedExecute(
    CallsStructs.ExecuteRequest[] calldata _executeRequests
  ) external returns (bytes[] memory);
}

