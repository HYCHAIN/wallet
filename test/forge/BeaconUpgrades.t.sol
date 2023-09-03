// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { BeaconProxyFactory } from "contracts/BeaconProxyFactory.sol";
import { Main, IMain } from "contracts/modules/Main/Main.sol";

import "forge-std/console.sol";

contract MainImpl is Main {
    function isNew() public pure returns(bool) {
        return false;
    }
}

contract MainImplNew is Main {
    function isNew() public pure returns(bool) {
        return true;
    }
}

contract BeaconUpgradesTest is TestBase {
    BeaconProxyFactory _factory;
    MainImpl _wallet1;
    MainImpl _wallet2;
    bytes32 _wallet1Salt = keccak256(bytes("_wallet1"));
    bytes32 _wallet2Salt = keccak256(bytes("_wallet2"));
    UpgradeableBeacon _beacon;

    function setUp() public {
        _factory = new BeaconProxyFactory(address(new MainImpl()));
        _wallet1 = MainImpl(payable(_factory.createProxy(_wallet1Salt)));
        _wallet2 = MainImpl(payable(_factory.createProxy(_wallet2Salt)));
        _beacon = UpgradeableBeacon(_factory.beacon());
    }

    function testCreateBySignatureInitializesSigner() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256("Approve HYTOPIA wallet creation"));
        address _newWallet = _factory.createProxyFromSignature(sig);
        assertEq(1, Main(payable(_newWallet)).controllerWeight(signingAuthority));
    }

    function testChangeBeaconUpdatesSingleProxy() public {
        assertFalse(_wallet1.isNew());
        MainImplNew _newImpl = new MainImplNew();
        _beacon.upgradeTo(address(_newImpl));
        assertTrue(_wallet1.isNew());
    }

    function testChangingBeaconUpdatesManyProxies() public {
        assertFalse(_wallet1.isNew());
        assertFalse(_wallet2.isNew());
        MainImplNew _newImpl = new MainImplNew();
        _beacon.upgradeTo(address(_newImpl));
        assertTrue(_wallet1.isNew());
        assertTrue(_wallet2.isNew());
    }
}
