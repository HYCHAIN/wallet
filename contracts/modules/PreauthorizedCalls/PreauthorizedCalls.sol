// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hychain.com
//
pragma solidity 0.8.23;

import "contracts/interfaces/IPreauthorizedCalls.sol";
import "../Calls/Calls.sol";
import "./PreauthorizedCallsStorage.sol";

contract PreauthorizedCalls is IPreauthorizedCalls, Calls {
    error CallNotPreauthorized();
    error CallTimelocked();
    error CallIntervalUnmet();
    error CallMaxCallsReached();
    error MaxCallsMustNotBeZero();

    /**
     * @dev Preauthorize a specific call for a given caller.
     * @param _callRequestPreauthorized The call to be preauthorized.
     * @param _callRequestPreauthorization The preauthorization details.
     * @param _nonce The nonce of the transaction to prevent replay attacks.
     * @param _signatures The signatures of the controllers to execute the transaction.
     */
    function preauthorizeCall(
        PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
        PreauthorizedCallsStructs.CallRequestPreauthorization calldata _callRequestPreauthorization,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(
                abi.encode(_callRequestPreauthorized, _callRequestPreauthorization, _nonce, _deadline, block.chainid)
            ),
            _deadline,
            _signatures
        );
        if (_callRequestPreauthorization.maxCalls == 0) {
            revert MaxCallsMustNotBeZero();
        }
        bytes32 _key = keccak256(
            abi.encode(
                _callRequestPreauthorized.caller,
                _callRequestPreauthorized.target,
                _callRequestPreauthorized.value,
                _callRequestPreauthorized.data
            )
        );
        PreauthorizedCallsStorage.layout().callRequestPreauthorizations[_key] = _callRequestPreauthorization;
    }

    /**
     * @dev Remove a preauthorization.
     * @param _callRequestPreauthorized The call that was preauthorized to be unpreauthorized.
     * @param _nonce The nonce of the transaction to prevent replay attacks.
     * @param _signatures The signatures of the controllers to execute the transaction.
     */
    function unauthorizeCall(
        PreauthorizedCallsStructs.CallRequestPreauthorized calldata _callRequestPreauthorized,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_callRequestPreauthorized, _nonce, _deadline, block.chainid)), _deadline, _signatures
        );
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

    /**
     * @dev Execute a preauthorized call. Validates that preauthorization was given and hasn't expired.
     * @param _callRequest The call to execute
     */
    function preauthorizedCall(CallsStructs.CallRequest calldata _callRequest) public returns (bytes memory) {
        PreauthorizedCallsStructs.CallRequestPreauthorization storage crp =
            getCallRequestPreauthorization(msg.sender, _callRequest);

        if (crp.maxCalls == 0) {
            // check if preauthorized for any caller.
            crp = getCallRequestPreauthorization(address(0), _callRequest);
        }

        if (crp.maxCalls == 0) {
            revert CallNotPreauthorized();
        }
        if (crp.unlockTimestamp != 0 && block.timestamp < crp.unlockTimestamp) {
            revert CallTimelocked();
        }
        if (
            crp.lastCallTimestamp != 0 && crp.minCallInterval != 0
                && (block.timestamp < crp.lastCallTimestamp + crp.minCallInterval)
        ) {
            revert CallIntervalUnmet();
        }
        if (crp.callCount >= crp.maxCalls) {
            revert CallMaxCallsReached();
        }

        crp.callCount += 1;
        crp.lastCallTimestamp = uint64(block.timestamp);

        return _call(_callRequest);
    }

    /**
     * @dev Execute multiple preauthorized calls at once. Validates that preauthorization was given and hasn't expired.
     * @param _callRequests The calls to execute
     */
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

    /**
     * @dev Get the preauthorization status for a given caller and call.
     * @param _caller The address to check a preauthorization for.
     * @param _callRequest The call to check a preauthorization for.
     */
    function getCallRequestPreauthorization(
        address _caller,
        CallsStructs.CallRequest calldata _callRequest
    ) private view returns (PreauthorizedCallsStructs.CallRequestPreauthorization storage) {
        return PreauthorizedCallsStorage.layout().callRequestPreauthorizations[keccak256(
            abi.encode(_caller, _callRequest.target, _callRequest.value, _callRequest.data)
        )];
    }

    /**
     * @dev Check if the contract supports an interface.
     * @param interfaceId The interface ID to check for support.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Calls) returns (bool) {
        if (interfaceId == type(IPreauthorizedCalls).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
