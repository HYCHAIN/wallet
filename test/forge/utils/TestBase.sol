// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { TestUtilities } from "./TestUtilities.sol";
import { TestErrors } from "./TestErrors.sol";
import { TestLogging } from "./TestLogging.sol";
import { TestProxyUtilities } from "./TestProxyUtilities.sol";
import { TestSessionUtilities } from "./TestSessionUtilities.sol";

abstract contract TestBase is Test, TestUtilities, TestErrors, TestLogging, TestProxyUtilities, TestSessionUtilities {
    address internal leet = address(0x1337);
    address internal alice = address(0xa11ce);
    address internal deployer = address(this);

    uint256 internal signingPK = 1;
    address internal signingAuthority = vm.addr(signingPK);

    constructor() {
        vm.label(leet, "L33T");
        vm.label(alice, "Alice");
        vm.label(deployer, "Deployer");
    }
}
