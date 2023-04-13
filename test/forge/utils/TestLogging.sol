// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";

abstract contract TestLogging {
    function debug(uint256 p0) internal view {
        console.log(p0);
    }

    function debug(string memory p0) internal view {
        console.log(p0);
    }

    function debug(bool p0) internal view {
        console.log(p0);
    }

    function debug(string memory label, bool p0) internal view {
        console.log(label, p0);
    }

    function debug(address p0) internal view {
        console.log(p0);
    }

    function debug(string memory label, address p0) internal view {
        console.log(label, p0);
    }

    function debug(int256 p0) internal view {
        console.logInt(p0);
    }

    function debugBytes(bytes memory p0) internal view {
        console.logBytes(p0);
    }

    function debugBytes32(bytes32 p0) internal view {
        console.logBytes32(p0);
    }
}
