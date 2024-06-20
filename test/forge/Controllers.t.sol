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
        meetsControllersThreshold(keccak256(abi.encode(block.chainid)), 99999999, _signatures)
    {
        didSomething = true;
    }

    function doSomethingWithConsensus(
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external meetsControllersThreshold(keccak256(abi.encode(block.chainid)), _deadline, _signatures) {
        didSomething = true;
    }
}

contract ControllersTest is TestBase {
    ControllersImpl _controllers;

    uint256 internal defaultControllerWeight = 1;
    uint256 internal defaultThreshold = 1;
    uint256 internal defaultNonce = 1;
    uint256 internal nonceCur = 2;

    uint256 _deadline = 9999999;

    function setUp() public {
        _controllers = ControllersImpl(proxify(address(new ControllersImpl())));
        _controllers.initialize(signingAuthority);
    }

    function _addController(address _addr) internal {
        bytes memory sig = signHashAsMessage(
            signingPK,
            keccak256(
                abi.encode(
                    arraySingle(_addr), arraySingle(defaultControllerWeight), ++nonceCur, _deadline, block.chainid
                )
            )
        );
        _controllers.addControllers(
            arraySingle(_addr), arraySingle(defaultControllerWeight), nonceCur, arraySingle(sig), _deadline
        );
    }

    function testRevertRunTxWithoutControllersOrThresholds() public {
        ControllersImpl controller = ControllersImpl(proxify(address(new ControllersImpl())));
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.doSomethingWithConsensus(new bytes[](0));
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.updateControlThreshold(defaultThreshold, 0, new bytes[](0), _deadline);
        vm.expectRevert(Controllers.ControllersNotInitialized.selector);
        controller.addControllers(
            arraySingle(deployer), arraySingle(defaultControllerWeight), defaultNonce, new bytes[](0), _deadline
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
        bytes memory sigThreshold = signHashAsMessage(
            signingPK, keccak256(abi.encode(defaultThreshold + 1, ++nonceCur, _deadline, block.chainid))
        );
        _controllers.updateControlThreshold(defaultThreshold + 1, nonceCur, arraySingle(sigThreshold), _deadline);
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));

        vm.expectRevert("Signer weights does not meet threshold");
        _controllers.doSomethingWithConsensus(arraySingle(sig));
    }

    function testAllowRemoveController() public {
        bytes memory sig = signHashAsMessage(
            signingPK, keccak256(abi.encode(arraySingle(alice), arraySingle(19), ++nonceCur, _deadline, block.chainid))
        );
        _controllers.addControllers(arraySingle(alice), arraySingle(19), nonceCur, arraySingle(sig), _deadline);
        _addController(deployer);

        assertEq(1, _controllers.controlThreshold());

        sig = signHashAsMessage(
            signingPK, keccak256(abi.encode(arraySingle(deployer), 20, defaultNonce, _deadline, block.chainid))
        );

        assertEq(1, _controllers.controllerWeight(deployer));

        _controllers.removeControllers(arraySingle(deployer), 20, defaultNonce, arraySingle(sig), _deadline);

        assertEq(0, _controllers.controllerWeight(deployer));
        // ensure new threshold was set
        assertEq(20, _controllers.controlThreshold());
    }

    function testReplaceController() public {
        _addController(deployer);
        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(deployer, alice, defaultNonce, _deadline, block.chainid)));

        assertEq(2, _controllers.controllersTotalWeight());
        assertEq(1, _controllers.controllerWeight(deployer));
        assertEq(0, _controllers.controllerWeight(alice));
        assertEq(1, _controllers.controlThreshold());

        _controllers.replaceController(deployer, alice, defaultNonce, arraySingle(sig), _deadline);

        assertEq(2, _controllers.controllersTotalWeight());
        assertEq(0, _controllers.controllerWeight(deployer));
        assertEq(1, _controllers.controllerWeight(alice));
        assertEq(1, _controllers.controlThreshold());

        sig = signHashAsMessage(
            signingPK, keccak256(abi.encode(deployer, alice, defaultNonce + 1, _deadline, block.chainid))
        );

        vm.expectRevert(Controllers.ControllerDoesNotExist.selector);
        _controllers.replaceController(deployer, alice, defaultNonce + 1, arraySingle(sig), _deadline);

        _addController(deployer);

        vm.expectRevert(Controllers.ControllerAlreadyExists.selector);
        _controllers.replaceController(deployer, alice, defaultNonce + 1, arraySingle(sig), _deadline);
    }

    function testAllowUpdateControllerWeight() public {
        uint256 newWeight = 2;
        _addController(deployer);
        uint256 totalWeight = _controllers.controllersTotalWeight();
        bytes memory sig = signHashAsMessage(
            signingPK, keccak256(abi.encode(deployer, newWeight, defaultNonce, _deadline, block.chainid))
        );

        assertEq(defaultControllerWeight, _controllers.controllerWeight(deployer));

        _controllers.updateControllerWeight(deployer, newWeight, defaultNonce, arraySingle(sig), _deadline);

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
        vm.assume(_numControllers > 0);
        _numControllers = _numControllers % 6 + 1;
        vm.assume(_threshold > 0);
        _threshold = _threshold % _numControllers + 1;
        uint256 pkOffset = 100;

        for (uint256 i = 0; i < _numControllers; i++) {
            _addController(vm.addr(i + pkOffset));
        }

        bytes memory sigThreshold =
            signHashAsMessage(signingPK, keccak256(abi.encode(_threshold, ++nonceCur, _deadline, block.chainid)));
        _controllers.updateControlThreshold(_threshold, nonceCur, arraySingle(sigThreshold), _deadline);

        bytes[] memory sigs = new bytes[](_threshold);

        for (uint256 i = 0; i < _threshold; i++) {
            sigs[i] = signHashAsMessage(i + pkOffset, keccak256(abi.encode(block.chainid)));
        }

        _controllers.doSomethingWithConsensus(sigs);
    }

    function testDeadlinePassedReverts() public {
        bytes memory sig = signHashAsMessage(signingPK, keccak256(abi.encode(block.chainid)));
        vm.expectRevert(Controllers.DeadlineReached.selector);
        _controllers.doSomethingWithConsensus(arraySingle(sig), block.timestamp - 1);
    }
}
