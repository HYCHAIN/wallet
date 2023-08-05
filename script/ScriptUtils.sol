// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Script.sol";
import { CREATE3Factory } from "@create3-factory/CREATE3Factory.sol";

import { BeaconProxyFactory } from "contracts/BeaconProxyFactory.sol";

/**
 * @dev A quick and dirty address organizer/network helper for foundry scripts. Nothing fancy here.
 */
contract ScriptUtils is Script {
    uint256 deployerPrivateKey;
    address deployer;

    // The create factory for the {ADD_DEPLOYER_ADDRESS_HERE} deployer
    CREATE3Factory internal _createFactory = CREATE3Factory(address(0)); // TODO: add address when deployed

    bytes32 internal _factorySalt = keccak256(bytes("FactoryTestnet1"));

    bytes32 internal _testWalletSalt = keccak256(bytes("TestWalletTestnet1"));

    // generated using the _createFactory + "FactoryTestnet1" salt for 0x.... deployer
    address internal _factoryAddress = address(0); // TODO: add address when deployed

    BeaconProxyFactory internal _factory = BeaconProxyFactory(_factoryAddress);

    constructor() {
        if (isPolygonMumbai()) {
            deployerPrivateKey = vm.envUint("DEV_PRIVATE_KEY");
        } else if (isLocalhost()) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            console2.log("Unsupported chain for script:", block.chainid);
            revert("unknown chain id");
        }
        deployer = vm.addr(deployerPrivateKey);
    }

    function isEthMainnet() public view returns (bool) {
        return block.chainid == 1;
    }

    function isGoerli() public view returns (bool) {
        return block.chainid == 5;
    }

    function isPolygonMainnet() public view returns (bool) {
        return block.chainid == 137;
    }

    function isPolygonMumbai() public view returns (bool) {
        return block.chainid == 80001;
    }

    function isLocalhost() public view returns (bool) {
        return block.chainid == 31337;
    }
}
