// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { Calls, CallsStructs, Controllers, ICalls } from "contracts/modules/Calls/Calls.sol";

import "forge-std/console.sol";

contract CallsImpl is Calls {
    bool public didSomething;

    function initialize(address _controller) public initializer {
        __Calls_init(_controller);
    }
}

contract Counter {
    uint256 public count;

    function increment(uint256 _amount) public {
        count += _amount;
    }
}

contract CallsTest is TestBase {
    CallsImpl _calls;
    Counter _counter;

    uint256 _deadline = 9999999;

    function setUp() public {
        _calls = CallsImpl(proxify(address(new CallsImpl())));
        _calls.initialize(signingAuthority);
        _counter = new Counter();
    }

    function testCallsRequireThreshold() public {
        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](1);
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: address(this), value: 1, data: new bytes(0), nonce: 1 });
        _callReqs[0] = _callReq;

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.call(_callReq, new bytes[](0), _deadline);

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.multiCall(_callReqs, new bytes[](0), _deadline);
    }

    function testRevertTransferInsufficientFundsWithConsensus() public {
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        assertEq(0, address(_calls).balance);
        assertEq(0, leet.balance);

        vm.expectRevert(ICalls.InsufficientFunds.selector);
        _calls.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );
    }

    function testAllowTransferFundsWithConsensus() public {
        vm.deal(address(_calls), 3 ether);
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        assertEq(3 ether, address(_calls).balance);
        assertEq(0, leet.balance);

        _calls.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );

        vm.expectRevert("At least one signature already used");
        _calls.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );

        assertEq(2 ether, address(_calls).balance);
        assertEq(1 ether, leet.balance);

        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](2);
        _callReqs[0] = _callReq;
        _callReqs[1] = CallsStructs.CallRequest({ target: alice, value: 0.5 ether, data: "", nonce: 1 });
        assertEq(0, alice.balance);

        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );

        assertEq(0.5 ether, address(_calls).balance);
        assertEq(2 ether, leet.balance);
        assertEq(0.5 ether, alice.balance);
    }

    function testAllowContractCallsWithConsensus() public {
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_counter),
            value: 0,
            data: abi.encodeWithSelector(Counter.increment.selector, 1),
            nonce: 1
        });
        assertEq(0, _counter.count());

        _calls.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );

        vm.expectRevert("At least one signature already used");
        _calls.call(
            _callReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, _deadline, block.chainid)))),
            _deadline
        );

        assertEq(1, _counter.count());

        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](2);
        _callReqs[0] = _callReq;
        _callReqs[1] = CallsStructs.CallRequest({
            target: address(_counter),
            value: 0,
            data: abi.encodeWithSelector(Counter.increment.selector, 8),
            nonce: 2
        });

        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );

        assertEq(10, _counter.count());
    }

    function testAllowMixedCallsWithConsensus() public {
        vm.deal(address(_calls), 3 ether);

        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](3);
        _callReqs[0] = CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        _callReqs[1] = CallsStructs.CallRequest({
            target: address(_counter),
            value: 0,
            data: abi.encodeWithSelector(Counter.increment.selector, 100),
            nonce: 1
        });
        _callReqs[2] = CallsStructs.CallRequest({ target: alice, value: 1 ether, data: "", nonce: 1 });
        assertEq(3 ether, address(_calls).balance);
        assertEq(0, alice.balance);
        assertEq(0, leet.balance);

        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );

        assertEq(1 ether, address(_calls).balance);
        assertEq(1 ether, leet.balance);
        assertEq(1 ether, alice.balance);
        assertEq(100, _counter.count());

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, _deadline, block.chainid)))),
            _deadline
        );
    }

    function testDeadlineReachedReverts() public {
        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](3);
        _callReqs[0] = CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        _callReqs[1] = CallsStructs.CallRequest({
            target: address(_counter),
            value: 0,
            data: abi.encodeWithSelector(Counter.increment.selector, 100),
            nonce: 1
        });
        _callReqs[2] = CallsStructs.CallRequest({ target: alice, value: 1 ether, data: "", nonce: 1 });
        bytes[] memory _sigs = arraySingle(
            signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.timestamp - 1, block.chainid)))
        );
        vm.expectRevert(Controllers.DeadlineReached.selector);
        _calls.multiCall(_callReqs, _sigs, block.timestamp - 1);

        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });

        _sigs = arraySingle(
            signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.timestamp - 1, block.chainid)))
        );
        vm.expectRevert(Controllers.DeadlineReached.selector);
        _calls.call(_callReq, _sigs, block.timestamp - 1);
    }

    function testCreateContractWithConsensus() public {
        CallsStructs.CreateRequest memory _createReq = CallsStructs.CreateRequest({
            salt: 0,
            nonce: 1,
            bytecode: abi.encodePacked(type(Counter).creationCode),
            initCode: ""
        });
        assertEq(0, address(_calls).balance);

        address _counterAddr = _calls.create(
            _createReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_createReq, _deadline, block.chainid)))),
            _deadline
        );

        Counter(_counterAddr).increment(5);
        assertEq(5, Counter(_counterAddr).count());

        vm.expectRevert("At least one signature already used");
        _calls.create(
            _createReq,
            arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_createReq, _deadline, block.chainid)))),
            _deadline
        );
    }
}
