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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Calls } from "../Calls/Calls.sol";
import { Controllers } from "../Controllers/Controllers.sol";
import { ERC1271 } from "../ERC1271/ERC1271.sol";
import { Versioned } from "../Versioned/Versioned.sol";
import { Hooks } from "../Hooks/Hooks.sol";
import { PreauthorizedCalls } from "../PreauthorizedCalls/PreauthorizedCalls.sol";
import { MainStorage } from "./MainStorage.sol";
import { IMain } from "./IMain.sol";

contract Main is IMain, Initializable, Versioned, PreauthorizedCalls, Hooks, ERC1271 {
    string public constant version = "alpha-1.0.0";

    function initialize(address _controller) external initializer {
        __Controllers_init(_controller);
    }

    function supportsInterface(bytes4 _interfaceID)
        public
        view
        override(PreauthorizedCalls, ERC1271)
        returns (bool)
    {
        return super.supportsInterface(_interfaceID);
    }
}
