// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import { CREATE3Factory } from "@create3-factory/CREATE3Factory.sol";

import { ScriptUtils } from "script/ScriptUtils.sol";

// example script cli:
//   forge script script/deploy/create3/DeployCreate3Factory.s.sol --fork-url http://localhost:8545 --broadcast

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
