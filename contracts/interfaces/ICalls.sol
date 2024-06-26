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

import "contracts/modules/Calls/CallsStructs.sol";

interface ICalls {
    error CreateInitCodeFailed();
    error RevertWithoutMessage();
    error InsufficientFunds();

    function call(
        CallsStructs.CallRequest calldata _callRequest,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external returns (bytes memory);

    function multiCall(
        CallsStructs.CallRequest[] calldata _callRequests,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external returns (bytes[] memory);
}
