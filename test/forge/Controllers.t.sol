// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";
import { Controllers, ControllersStorage } from "contracts/modules/Controllers/Controllers.sol";

import "forge-std/console.sol";

contract ControllersImpl is Controllers {
    bool public didSomething;

    function initialize(address _controller) public initializer {
        __Controllers_init(_controller);
    }

    function doSomethingWithConsensus(bytes[] calldata _signatures)
        external
        meetsControllersThreshold(keccak256(abi.encode(block.chainid)), _signatures)
    {
        didSomething = true;
    }
}

contract ControllersTest is TestBase {
    ControllersImpl _controllers;

    uint256 internal defaultControllerWeight = 1;
    uint256 internal defaultThreshold = 1;
    uint256 internal defaultNonce = 1;
    uint256 internal nonceCur = 2;

    function setUp() public {
        _controllers = ControllersImpl(proxify(address(new ControllersImpl())));
        _controllers.initialize(signingAuthority);
    }

    function _addController(address _addr) internal {
        bytes memory sig = signHashAsMessage(
            signingPK,
            keccak256(abi.encode(arraySingle(_addr), arraySingle(defaultControllerWeight), ++nonceCur, block.chainid))
        );
        _controllers.addControllers(
            arraySingle(_addr), arraySingle(defaultControllerWeight), nonceCur, arraySingle(sig)
        );
    }

    function testRevertRunTxWithoutControllersOrThresholds() public {
        ControllersImpl controller = ControllersImpl(proxify(address(new ControllersImpl())));
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.doSomethingWithConsensus(new bytes[](0));
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.updateControlThreshold(defaultThreshold, 0, new bytes[](0));
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.addControllers(
            arraySingle(deployer), arraySingle(defaultControllerWeight), defaultNonce, new bytes[](0)
        );
    }

    function testRevertRunTxWithoutControllerConsensus() public {
        vm.expectRevert("Signer weights does not meet threshold");
        _controllers.doSomethingWithConsensus(new bytes[](0));
    }

    function testAllowRunTxWithControllerConsensus() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));
        _controllers.doSomethingWithConsensus(arraySingle(sig));

        assertTrue(_controllers.didSomething());
    }

    function testAllowRunTxConsensusExtraControllers() public {
        _addController(deployer);
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));
        _controllers.doSomethingWithConsensus(arraySingle(sig));

        assertTrue(_controllers.didSomething());
    }

    function testRevertRunTxPartialConsensus() public {
        _addController(deployer);
        bytes memory sigThreshold =
            signHashAsMessage(signingPK, keccak256(abi.encode(defaultThreshold + 1, ++nonceCur, block.chainid)));
        _controllers.updateControlThreshold(defaultThreshold + 1, nonceCur, arraySingle(sigThreshold));
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));

        vm.expectRevert("Signer weights does not meet threshold");
        _controllers.doSomethingWithConsensus(arraySingle(sig));
    }

    function testAllowRemoveController() public {
        _addController(deployer);
        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(arraySingle(deployer), defaultNonce, block.chainid)));

        assertEq(1, _controllers.controllerWeight(deployer));

        _controllers.removeControllers(arraySingle(deployer), defaultNonce, arraySingle(sig));

        assertEq(0, _controllers.controllerWeight(deployer));
    }

    function testAllowUpdateControllerWeight() public {
        uint256 newWeight = 2;
        _addController(deployer);
        uint256 totalWeight = _controllers.controllersTotalWeight();
        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(deployer, newWeight, defaultNonce, block.chainid)));

        assertEq(defaultControllerWeight, _controllers.controllerWeight(deployer));

        _controllers.updateControllerWeight(deployer, newWeight, defaultNonce, arraySingle(sig));

        assertEq(newWeight, _controllers.controllerWeight(deployer));
        assertEq(totalWeight + (newWeight - defaultControllerWeight), _controllers.controllersTotalWeight());
    }

    function testRevertReusingSig() public {
        _addController(deployer);
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));

        _controllers.doSomethingWithConsensus(arraySingle(sig));

        vm.expectRevert("At least one signature already used");
        _controllers.doSomethingWithConsensus(arraySingle(sig));
    }

    function testControllerThresholdsEqualWeightsFuzz(uint256 _numControllers, uint256 _threshold) public {
        vm.assume(_numControllers > 0 && _numControllers <= 6);
        vm.assume(_threshold > 0 && _threshold <= _numControllers);
        uint256 pkOffset = 100;

        for (uint256 i = 0; i < _numControllers; i++) {
            _addController(vm.addr(i + pkOffset));
        }

        bytes memory sigThreshold =
            signHashAsMessage(signingPK, keccak256(abi.encode(_threshold, ++nonceCur, block.chainid)));
        _controllers.updateControlThreshold(_threshold, nonceCur, arraySingle(sigThreshold));

        bytes[] memory sigs = new bytes[](_threshold);

        for (uint256 i = 0; i < _threshold; i++) {
            sigs[i] = signHashAsMessage(i + pkOffset, keccak256(abi.encode(block.chainid)));
        }

        _controllers.doSomethingWithConsensus(sigs);
    }
}
