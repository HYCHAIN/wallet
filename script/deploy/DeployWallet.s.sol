// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Script.sol";

import {Main, IMain} from "contracts/modules/Main/Main.sol";
import {IUpgrades} from "contracts/modules/Upgrades/IUpgrades.sol";
import {Wallet} from "contracts/Wallet.sol";

import {ScriptUtils} from "script/ScriptUtils.sol";

// example script cli:
//   forge script script/deploy/DeployWallet.s.sol --rpc-url mumbai --broadcast --verify

/**
 * @dev Deploys a new wallet using the MetaFab Wallet Factory.
 *     The wallet is deployed as a minimal proxy with the Main contract as the implementation.
 *     The wallet is tested against containing the IUpgrades interface to ensure correctness.
 */
contract WalletDeployer is Script, ScriptUtils {

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        Main _main = new Main();

        address _newWalletAddr = _factory.deployWithControllerUnsigned(
            address(_main),
            deployer,
            _testWalletSalt
        );

        console2.log("Wallet deployed -->", _newWalletAddr);
        
        bool _supportsUpgrades = IUpgrades(_newWalletAddr).supportsUpgrades();
        console2.log("Supports upgrades? -->", _supportsUpgrades);

        vm.stopBroadcast();
    }
}