// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { Calls, CallsStructs } from "contracts/modules/Calls/Calls.sol";
import { BeaconProxyFactory } from "contracts/BeaconProxyFactory.sol";
import { Main, IMain } from "contracts/modules/Main/Main.sol";

import "forge-std/console.sol";

contract MainImpl is Main {
    function isNew() public pure returns (bool) {
        return false;
    }
}

contract MainImplNew is Main {
    function isNew() public pure returns (bool) {
        return true;
    }
}

contract MainTest is TestBase {
    BeaconProxyFactory _factory;
    MainImpl _wallet1;
    bytes32 _wallet1Salt = keccak256(bytes("_wallet1"));
    UpgradeableBeacon _beacon;

    uint256 _deadline = 9999999;

    function setUp() public {
        _factory = new BeaconProxyFactory(address(new MainImpl()));
        vm.prank(signingAuthority);
        address _walletAddr = _factory.createProxy(_wallet1Salt);
        _wallet1 = MainImpl(payable(_walletAddr));
        _beacon = UpgradeableBeacon(_factory.beacon());
    }

    function testMainRevertTransferInsufficientFunds() public {
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        assertEq(0, address(_wallet1).balance);
        assertEq(0, leet.balance);

        vm.expectRevert("Insufficient funds to transfer");
        _wallet1.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );
    }

    function testCanReceiveNativeToken() public {
        vm.deal(deployer, 1 ether);
        assertEq(0, address(_wallet1).balance);
        assertEq(1 ether, deployer.balance);

        (bool _success, bytes memory _data) = payable(address(_wallet1)).call{ value: 1 ether }("");

        assertTrue(_success);
        assertEq("", _data);
        assertEq(1 ether, address(_wallet1).balance);
        assertEq(0, deployer.balance);
    }
}
