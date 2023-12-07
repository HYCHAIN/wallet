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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Calls } from "../Calls/Calls.sol";
import { Controllers } from "../Controllers/Controllers.sol";
import { ERC1271 } from "../ERC1271/ERC1271.sol";
import { Versioned } from "../Versioned/Versioned.sol";
import { PreauthorizedCalls } from "../PreauthorizedCalls/PreauthorizedCalls.sol";
import { MainStorage } from "./MainStorage.sol";
import { IMain } from "contracts/interfaces/IMain.sol";

contract Main is IMain, Initializable, Versioned, PreauthorizedCalls, ERC1155Holder, ERC721Holder, ERC1271 {
    string public constant version = "alpha-1.0.0";

    function initialize(address _controller) external initializer {
        __Controllers_init(_controller);
    }

    function supportsInterface(bytes4 _interfaceID)
        public
        view
        override(PreauthorizedCalls, ERC1271, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(_interfaceID);
    }
}
