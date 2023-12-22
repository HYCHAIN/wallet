// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { WalletProxyFactory } from "contracts/WalletProxyFactory.sol";
import { Main, IMain, MainStorage } from "contracts/modules/Main/Main.sol";

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

contract NonUUPSContract {
    function isNew() public pure returns (bool) {
        return true;
    }
}

contract UUPSUpgradesTest is TestBase {
    WalletProxyFactory _factory;
    MainImpl _wallet1;
    MainImpl _wallet2;
    bytes32 _wallet1Salt = keccak256(bytes("_wallet1"));
    bytes32 _wallet2Salt = keccak256(bytes("_wallet2"));

    uint256 _deadline = 9999999;

    function setUp() public {
        _factory = new WalletProxyFactory(address(new MainImpl()));
        _wallet1 = MainImpl(payable(_factory.createProxy(_wallet1Salt)));
        _wallet2 = MainImpl(payable(_factory.createProxy(_wallet2Salt)));
    }

    function testCreateBySignatureInitializesSigner() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256("Approve HYTOPIA wallet creation"));
        address _newWallet = _factory.createProxyFromSignature(sig);
        assertEq(1, Main(payable(_newWallet)).controllerWeight(signingAuthority));
    }

    function testChangeUUPSImplOnlyUpdatesSingleProxy() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256("Approve HYTOPIA wallet creation"));
        MainImpl _newWallet = MainImpl(payable(_factory.createProxyFromSignature(sig)));
        assertFalse(_newWallet.isNew());
        MainImplNew _newImpl = new MainImplNew();
        // Can't upgrade with regular UUPSUpgradeable function call, must use the controller upgrade function
        vm.expectRevert(MainStorage.UnauthorizedUpgrade.selector);
        _newWallet.upgradeToAndCall(address(_newImpl), "");
        assertFalse(_newWallet.isNew());

        // Can upgrade with controller upgrade function
        _newWallet.upgradeToAndCall(
            address(_newImpl),
            "",
            arraySingle(
                signHashAsMessage(signingPK, keccak256(abi.encode(address(_newImpl), "", _deadline, block.chainid)))
            ),
            _deadline
        );
        assertTrue(_newWallet.isNew());
        // other deployed proxies are unchanged
        assertFalse(_wallet1.isNew());
        assertFalse(_wallet2.isNew());
    }

    function testUpgradeToNonUUPSFails() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256("Approve HYTOPIA wallet creation"));
        MainImpl _newWallet = MainImpl(payable(_factory.createProxyFromSignature(sig)));
        NonUUPSContract _newImpl = new NonUUPSContract();

        vm.expectRevert(abi.encodeWithSelector(ERC1967Utils.ERC1967InvalidImplementation.selector, address(_newImpl)));
        _newWallet.upgradeToAndCall(
            address(_newImpl),
            "",
            arraySingle(
                signHashAsMessage(signingPK, keccak256(abi.encode(address(_newImpl), "", _deadline, block.chainid)))
            ),
            _deadline
        );
    }

    function testRevertUpgradeWithoutThreshold() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256("Approve HYTOPIA wallet creation"));
        MainImpl _newWallet = MainImpl(payable(_factory.createProxyFromSignature(sig)));
        MainImplNew _newImpl = new MainImplNew();

        vm.expectRevert("Signer weights does not meet threshold");
        _newWallet.upgradeToAndCall(address(_newImpl), "", new bytes[](0), _deadline);
    }
}
