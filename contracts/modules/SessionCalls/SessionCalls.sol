// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./ISessionCalls.sol";
import "../Calls/Calls.sol";
import "./SessionCallsStorage.sol";

contract SessionCalls is ISessionCalls, Calls {
  function startSession(
    address caller,
    SessionCallsStructs.Session calldata _session,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(caller, _session, _nonce, block.chainid)), _signatures)
  {
    SessionCallsStorage.layout().sessions[caller] = _session;
  }

  function endSession(
    address caller,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(caller, _nonce, block.chainid)), _signatures)
  {
    delete SessionCallsStorage.layout().sessions[caller];
  }

  function sessionCall(
    CallsStructs.CallRequest calldata _callRequest
  )
    public
    returns (bytes memory)
  {
    SessionCallsStructs.Session storage session = SessionCallsStorage.layout().sessions[msg.sender];

    require(
      session.expiresAt != 0 ||
      session.approvedSystemIds.length > 0 ||
      session.approvedContracts.length > 0 ||
      session.approvedFunctionSelectors.length > 0,
      "Session does not exist"
    );

    require(session.expiresAt == 0 || session.expiresAt < block.timestamp, "Session expired");
    
    if (session.approvedSystemIds.length > 0) {
      // check if target implements system interface, if so check if its system id is approved
    }

    if (session.approvedContracts.length > 0) {
      bool approvedContract = false;
      for (uint256 i = 0; i < session.approvedContracts.length; i++) {
        if (session.approvedContracts[i] == _callRequest.target) {
          approvedContract = true;
          break;
        }
      }
      require(approvedContract, "Target contract not approved for session");
    }

    if (session.approvedFunctionSelectors.length > 0) {
      bytes4 functionSelector = bytes4(_callRequest.data);
      bool approvedFunctionSelector = false;
      for (uint256 i = 0; i < session.approvedFunctionSelectors.length; i++) {
        if (session.approvedFunctionSelectors[i] == functionSelector) {
          approvedFunctionSelector = true;
          break;
        }
      }
      require(approvedFunctionSelector, "Function selector not approved for session");
    }

    return _call(_callRequest);
  }

  function sessionMultiCall(
    CallsStructs.CallRequest[] calldata _callRequests
  )
    external
    returns (bytes[] memory)
  {
    bytes[] memory results = new bytes[](_callRequests.length);

    for (uint256 i = 0; i < _callRequests.length; i++) {
      results[i] = sessionCall(_callRequests[i]);
    }

    return results;
  }
}