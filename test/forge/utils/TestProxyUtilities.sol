// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

abstract contract TestProxyUtilities {

    function proxify(address implementation) internal returns (address proxy) {
        proxy = Clones.clone(implementation);
    }
}
