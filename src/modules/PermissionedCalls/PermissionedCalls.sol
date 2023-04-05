// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./IPermissionedCalls.sol";
import "../Calls/Calls.sol";
import "./PermissionedCallsStorage.sol";

abstract contract PermissionedCalls is IPermissionedCalls, Calls {
  function permitExecute(
    PermissionedCallsStructs.ExecuteRequestPermitted calldata _executeRequestPermitted,
    PermissionedCallsStructs.ExecuteRequestPermission calldata _executeRequestPermission,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_executeRequestPermitted, _executeRequestPermission, _nonce, block.chainid)), _signatures)
  {
    require(_executeRequestPermission.maxExecutes > 0, "ExecuteRequestPermission.maxExecutes must not be 0");

    PermissionedCallsStorage.layout().executeRequestPermissions[
      keccak256(
        abi.encode(
          _executeRequestPermitted.executor,
          _executeRequestPermitted.target,
          _executeRequestPermitted.value,
          _executeRequestPermitted.data
        )
      )
    ] = _executeRequestPermission;
  }

  function unpermitExecute(
    PermissionedCallsStructs.ExecuteRequestPermitted calldata _executeRequestPermitted,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_executeRequestPermitted, _nonce, block.chainid)), _signatures)
  {
    delete PermissionedCallsStorage.layout().executeRequestPermissions[
      keccak256(
        abi.encode(
          _executeRequestPermitted.executor,
          _executeRequestPermitted.target,
          _executeRequestPermitted.value,
          _executeRequestPermitted.data
        )
      )
    ];
  }

  function permittedExecute(CallsStructs.ExecuteRequest calldata _executeRequest) public returns (bytes memory) {
    PermissionedCallsStructs.ExecuteRequestPermission storage erp = getExecuteRequestPermission(msg.sender, _executeRequest);

    if (erp.maxExecutes == 0) { // check if permitted by any executor.
      erp = getExecuteRequestPermission(address(0), _executeRequest);
    }

    require(erp.maxExecutes > 0, "Execution not permitted");
    require(erp.unlockTimestamp == 0 || block.timestamp >= erp.unlockTimestamp, "Execution timelocked");
    require(erp.lastExecuteTimestamp == 0 || erp.minExecuteInterval == 0 || (block.timestamp >= erp.lastExecuteTimestamp + erp.minExecuteInterval), "Execution interval unmet");
    require(erp.executeCount < erp.maxExecutes, "Max executions reached");

    erp.executeCount += 1;
    erp.lastExecuteTimestamp = uint64(block.timestamp);

    return _call(_executeRequest);
  }

  function multiPermittedExecute(CallsStructs.ExecuteRequest[] calldata _executeRequests) external returns (bytes[] memory) {
    bytes[] memory results = new bytes[](_executeRequests.length);

    for (uint256 i = 0; i < _executeRequests.length; i++) {
      results[i] = permittedExecute(_executeRequests[i]);
    }

    return results;
  }

  function getExecuteRequestPermission(address _executor, CallsStructs.ExecuteRequest calldata _executeRequest) private view returns (PermissionedCallsStructs.ExecuteRequestPermission storage) {
    return PermissionedCallsStorage.layout().executeRequestPermissions[
      keccak256(
        abi.encode(
          _executor,
          _executeRequest.target,
          _executeRequest.value,
          _executeRequest.data
        )
      )
    ];
  } 
}