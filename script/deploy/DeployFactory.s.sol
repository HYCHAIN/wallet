// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { CREATE3Factory } from "@create3-factory/CREATE3Factory.sol";

import { WalletProxyFactory } from "contracts/WalletProxyFactory.sol";
import { Main } from "contracts/modules/Main/Main.sol";

import { ScriptUtils } from "script/ScriptUtils.sol";

// example script cli:
//   PRIVATE_KEY=<pk> forge script script/deploy/DeployFactory.s.sol --rpc-url <your_rpc_url> --broadcast

/**
 * @dev Deploys a new Hychain Wallet Factory contract using the CREATE3Factory previously deployed.
 */
contract FactoryDeployer is Script, ScriptUtils {
    error Create2EmptyBytecode();

    error Create2FailedDeployment();

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        _createFactory = new CREATE3Factory();
        console2.log("CREATE3Factory deployed at -->", address(_createFactory));

        address _factoryAddr = _createFactory.getDeployed(deployer, _factorySalt);
        console2.log("Deploying Factory to -->", _factoryAddr);

        if (_factoryAddr.code.length != 0) {
            console2.log("Factory already deployed at -->", _factoryAddr);
            vm.stopBroadcast();
            return;
        }

        // Create a WalletProxyFactory with the Main contract as the beacon implementation.
        // This will cause the deployed factory to only deploy Main contracts pointing to this initial
        // UpgradeableBeacon deployment.
        // Main is the wallet contract with all desired features attached.
        address newFactoryAddr = _createFactory.deploy(
            _factorySalt, abi.encodePacked(type(WalletProxyFactory).creationCode, abi.encode(address(new Main())))
        );

        console2.log("Factory deployed -->", newFactoryAddr);
        vm.stopBroadcast();
    }

    function computeAddress(bytes32 salt, bytes32 creationCodeHash) public view returns (address addr) {
        address contractAddress = address(this);

        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x40), creationCodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, contractAddress)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

    function deploy(bytes32 salt, bytes memory creationCode) public payable returns (address addr) {
        if (creationCode.length == 0) {
            revert Create2EmptyBytecode();
        }
        console2.log("computed2: ", computeAddress(salt, keccak256(creationCode)));
        assembly {
            addr := create2(callvalue(), add(creationCode, 0x20), mload(creationCode), salt)
        }
        console2.log("deployed address: ", addr);
        console2.logBytes32(keccak256(creationCode));
        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
    }
}
