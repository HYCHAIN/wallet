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

import "../Calls/ICalls.sol";
import "./SessionCallsStructs.sol";

interface ISessionCalls is ICalls {
    function startSession(
        address _caller,
        SessionCallsStructs.SessionRequest calldata _sessionRequest,
        uint256 _expiresAt,
        uint256 _nonce,
        bytes[] calldata _signatures
    ) external;

    function endSessionForCaller(address _caller, uint256 _nonce, bytes[] calldata _signatures) external;

    function sessionCall(CallsStructs.CallRequest calldata _callRequest) external returns (bytes memory);

    function sessionMultiCall(CallsStructs.CallRequest[] calldata _callRequests) external returns (bytes[] memory);

    function hasActiveSession(address _caller) external view returns (bool hasSession_);
}
