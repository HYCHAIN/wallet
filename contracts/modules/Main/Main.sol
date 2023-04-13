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
import { Calls } from "../Calls/Calls.sol";
import { Controllers } from "../Controllers/Controllers.sol";
import { ERC1271 } from "../ERC1271/ERC1271.sol";
import { Versioned } from "../Versioned/Versioned.sol";
import { Hooks } from "../Hooks/Hooks.sol";
import { Upgrades } from "../Upgrades/Upgrades.sol";
import { PreauthorizedCalls } from "../PreauthorizedCalls/PreauthorizedCalls.sol";
import { MainStorage } from "./MainStorage.sol";
import { IMain } from "./IMain.sol";

contract Main is IMain, Initializable, Versioned, PreauthorizedCalls, Hooks, Upgrades, ERC1271 {
  string public constant version = "alpha-1.0.0";

  function initialize(address _controller) external initializer {
    __Controllers_init(_controller);
  }

  function supportsInterface(
    bytes4 _interfaceID
  ) public override(
    PreauthorizedCalls,
    Upgrades,
    ERC1271
  ) view returns (bool) {
    return super.supportsInterface(_interfaceID);
  }
}