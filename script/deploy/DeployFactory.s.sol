// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Script.sol";

import { Factory } from "contracts/Factory.sol";

import { ScriptUtils } from "script/ScriptUtils.sol";

// example script cli:
//   forge script script/deploy/DeployFactory.s.sol --rpc-url mumbai --broadcast --verify

/**
 * @dev Deploys a new MetaFab Wallet Factory contract using the CREATE3Factory previously deployed.
 */
contract FactoryDeployer is Script, ScriptUtils {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Deploying Factory to -->", _createFactory.getDeployed(deployer, _factorySalt));

        address newFactoryAddr =
            _createFactory.deploy(_factorySalt, abi.encodePacked(type(Factory).creationCode, abi.encode(deployer)));

        console2.log("Factory deployed -->", newFactoryAddr);
        vm.stopBroadcast();
    }
}
