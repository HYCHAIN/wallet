// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract Versioned is Initializable {
    constructor() {
        _disableInitializers();
    }

    function __Versioned_init() internal onlyInitializing { }

    function getCurrentVersion() external view returns (uint256) {
        return Initializable._getInitializedVersion();
    }
}
