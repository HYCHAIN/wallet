// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Script.sol";

import { BeaconProxyFactory } from "contracts/BeaconProxyFactory.sol";
import { Main } from "contracts/modules/Main/Main.sol";

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

        // Create a BeaconProxyFactory with the Main contract as the beacon implementation.
        // This will cause the deployed factory to only deploy Main contracts pointing to this initial
        // UpgradeableBeacon deployment.
        // Main is the wallet contract with all desired features attached.
        address newFactoryAddr = _createFactory.deploy(
            _factorySalt,
            abi.encodePacked(type(BeaconProxyFactory).creationCode, abi.encode(type(Main).creationCode))
        );

        console2.log("Factory deployed -->", newFactoryAddr);
        console2.log("Factory beacon address -->", BeaconProxyFactory(newFactoryAddr).beacon());
        vm.stopBroadcast();
    }
}
