// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Controllers.sol";

contract Main is Controllers {
  constructor(address _admin)
  Controllers(_admin)
  {}

  receive() external payable { }
}