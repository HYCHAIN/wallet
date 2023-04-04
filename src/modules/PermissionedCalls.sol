// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./interfaces/IPermissionedCalls.sol";
import "./Calls.sol";

abstract contract PermissionedCalls is IPermissionedCalls, Calls {
  mapping(bytes32 => ExecuteRequestPermission) private executeRequestPermissions;

  function permitExecute(
    ExecuteRequestPermitted calldata _executeRequestPermitted,
    ExecuteRequestPermission calldata _executeRequestPermission,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_executeRequestPermitted, _executeRequestPermission, _nonce, block.chainid)), _signatures)
  {
    require(_executeRequestPermission.maxExecutes > 0, "ExecuteRequestPermission.maxExecutes must not be 0");

    executeRequestPermissions[
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
    ExecuteRequestPermitted calldata _executeRequestPermitted,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_executeRequestPermitted, _nonce, block.chainid)), _signatures)
  {
    delete executeRequestPermissions[
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

  function permittedExecute(ExecuteRequest calldata _executeRequest) public returns (bytes memory) {
    ExecuteRequestPermission storage erp = executeRequestPermissions[
      keccak256(
        abi.encode(
          msg.sender,
          _executeRequest.target,
          _executeRequest.value,
          _executeRequest.data
        )
      )
    ];

    require(erp.maxExecutes > 0, "Execution not permitted");
    require(erp.unlockTimestamp == 0 || block.timestamp >= erp.unlockTimestamp, "Execution timelocked");
    require(erp.lastExecuteTimestamp == 0 || erp.minExecuteInterval == 0 || (block.timestamp >= erp.lastExecuteTimestamp + erp.minExecuteInterval), "Execution interval unmet");
    require(erp.executeCount < erp.maxExecutes, "Max executions reached");

    erp.executeCount += 1;
    erp.lastExecuteTimestamp = uint64(block.timestamp);

    return _call(_executeRequest);
  }

  function multiPermittedExecute(ExecuteRequest[] calldata _executeRequests) external returns (bytes[] memory) {
    bytes[] memory results = new bytes[](_executeRequests.length);

    for (uint256 i = 0; i < _executeRequests.length; i++) {
      results[i] = permittedExecute(_executeRequests[i]);
    }

    return results;
  }
}