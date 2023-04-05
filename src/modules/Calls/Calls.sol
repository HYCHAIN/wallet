// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./ICalls.sol";
import "../Controllers/Controllers.sol";

abstract contract Calls is ICalls, Controllers {
  function execute( // todo: should be eip712 sigs?
    CallsStructs.ExecuteRequest calldata _executeRequest,
    bytes[] calldata _signatures
  )
    external 
    meetsControllersThreshold(keccak256(abi.encode(_executeRequest, block.chainid)), _signatures) 
    returns (bytes memory) 
  {
    return _call(_executeRequest);
  }

  function multiExecute(
    CallsStructs.ExecuteRequest[] calldata _executeRequests,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_executeRequests, block.chainid)), _signatures)
    returns (bytes[] memory)
  {
    bytes[] memory results = new bytes[](_executeRequests.length);
        
    for (uint256 i = 0; i < _executeRequests.length; i++) {
      results[i] = _call(_executeRequests[i]);
    }

    return results;
  }

  function _call(CallsStructs.ExecuteRequest calldata _executeRequest) internal returns (bytes memory) {
    (bool success, bytes memory result) = _executeRequest.target.call{
      value : _executeRequest.value
    }(_executeRequest.data);

    if (!success) {
      assembly { revert(add(result, 32), mload(result)) }
    }

    return result;
  }
}


