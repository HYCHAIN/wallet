// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

interface IERC223Receiver {
    function tokenFallback(address, uint256, bytes calldata) external;
}