// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//

pragma solidity 0.8.18;

import "./IPreauthorizedCalls.sol";
import "../Calls/Calls.sol";
import "./PreauthorizedCallsStorage.sol";

contract PreauthorizedCalls is IPreauthorizedCalls, Calls {
    function preauthorizeCall(
        PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
        PreauthorizedCallsStructs.CallRequestPreauthorization calldata _callRequestPreauthorization,
        uint256 _nonce,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(
            keccak256(abi.encode(_callRequestPreauthorized, _callRequestPreauthorization, _nonce, block.chainid)),
            _signatures
        )
    {
        require(_callRequestPreauthorization.maxCalls > 0, "CallRequestPreauthorization.maxCalls must not be 0");

        PreauthorizedCallsStorage.layout().callRequestPreauthorizations[keccak256(
            abi.encode(
                _callRequestPreauthorized.caller,
                _callRequestPreauthorized.target,
                _callRequestPreauthorized.value,
                _callRequestPreauthorized.data
            )
        )] = _callRequestPreauthorization;
    }

    function unauthorizeCall(
        PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
        uint256 _nonce,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(keccak256(abi.encode(_callRequestPreauthorized, _nonce, block.chainid)), _signatures)
    {
        delete PreauthorizedCallsStorage.layout().callRequestPreauthorizations[
      keccak256(
        abi.encode(
          _callRequestPreauthorized.caller,
          _callRequestPreauthorized.target,
          _callRequestPreauthorized.value,
          _callRequestPreauthorized.data
        )
      )
    ];
    }

    function preauthorizedCall(CallsStructs.CallRequest calldata _callRequest) public returns (bytes memory) {
        PreauthorizedCallsStructs.CallRequestPreauthorization storage crp =
            getCallRequestPreauthorization(msg.sender, _callRequest);

        if (crp.maxCalls == 0) {
            // check if preauthorized for any caller.
            crp = getCallRequestPreauthorization(address(0), _callRequest);
        }

        require(crp.maxCalls > 0, "Call not preauthorized");
        require(crp.unlockTimestamp == 0 || block.timestamp >= crp.unlockTimestamp, "Call timelocked");
        require(
            crp.lastCallTimestamp == 0 || crp.minCallInterval == 0
                || (block.timestamp >= crp.lastCallTimestamp + crp.minCallInterval),
            "Call interval unmet"
        );
        require(crp.callCount < crp.maxCalls, "Max calls reached");

        crp.callCount += 1;
        crp.lastCallTimestamp = uint64(block.timestamp);

        return _call(_callRequest);
    }

    function preauthorizedMultiCall(CallsStructs.CallRequest[] calldata _callRequests)
        external
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](_callRequests.length);

        for (uint256 i = 0; i < _callRequests.length; i++) {
            results[i] = preauthorizedCall(_callRequests[i]);
        }

        return results;
    }

    function getCallRequestPreauthorization(
        address _caller,
        CallsStructs.CallRequest calldata _callRequest
    ) private view returns (PreauthorizedCallsStructs.CallRequestPreauthorization storage) {
        return PreauthorizedCallsStorage.layout().callRequestPreauthorizations[keccak256(
            abi.encode(_caller, _callRequest.target, _callRequest.value, _callRequest.data)
        )];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(Calls) returns (bool) {
        if (interfaceId == type(IPreauthorizedCalls).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
