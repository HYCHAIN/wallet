// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//
pragma solidity 0.8.23;

import "./ICalls.sol";
import "contracts/modules/PreauthorizedCalls/PreauthorizedCallsStructs.sol";

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

    function preauthorizedCall(CallsStructs.CallRequest calldata _callRequest) external returns (bytes memory);

    function preauthorizedMultiCall(CallsStructs.CallRequest[] calldata _callRequests)
        external
        returns (bytes[] memory);
}
