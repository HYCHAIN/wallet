// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Script.sol";
import { CREATE3Factory } from "@create3-factory/CREATE3Factory.sol";

import { ScriptUtils } from "script/ScriptUtils.sol";

/**
 * @dev Deploys a new CREATE3Factory contract.
 */
contract DeployScript is Script, ScriptUtils {
    function run() public returns (CREATE3Factory factory) {
        vm.startBroadcast(deployerPrivateKey);

        factory = new CREATE3Factory();

        vm.stopBroadcast();
    }
}
