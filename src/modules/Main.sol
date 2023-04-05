// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Calls/Calls.sol";
import "./Controllers/Controllers.sol";
import "./ERC1271.sol";
import "./Hooks/Hooks.sol";
import "./PermissionedCalls/PermissionedCalls.sol";

contract Main is PermissionedCalls, Hooks, ERC1271 {
  constructor(address _controller)
  Controllers(_controller)
  {}
}