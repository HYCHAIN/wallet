// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { Calls, CallsStructs } from "contracts/modules/Calls/Calls.sol";

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
        _calls.call(_callReq, new bytes[](0));

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.multiCall(_callReqs, new bytes[](0));
    }

    function testRevertTransferInsufficientFundsWithConsensus() public {
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        assertEq(0, address(_calls).balance);
        assertEq(0, leet.balance);

        vm.expectRevert();
        _calls.call(_callReq, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.chainid)))));
    }

    function testAllowTransferFundsWithConsensus() public {
        vm.deal(address(_calls), 3 ether);
        CallsStructs.CallRequest memory _callReq =
            CallsStructs.CallRequest({ target: leet, value: 1 ether, data: "", nonce: 1 });
        assertEq(3 ether, address(_calls).balance);
        assertEq(0, leet.balance);

        _calls.call(_callReq, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.chainid)))));

        vm.expectRevert("At least one signature already used");
        _calls.call(_callReq, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.chainid)))));

        assertEq(2 ether, address(_calls).balance);
        assertEq(1 ether, leet.balance);

        CallsStructs.CallRequest[] memory _callReqs = new CallsStructs.CallRequest[](2);
        _callReqs[0] = _callReq;
        _callReqs[1] = CallsStructs.CallRequest({ target: alice, value: 0.5 ether, data: "", nonce: 1 });
        assertEq(0, alice.balance);

        _calls.multiCall(
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
        );

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
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

        _calls.call(_callReq, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.chainid)))));

        vm.expectRevert("At least one signature already used");
        _calls.call(_callReq, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReq, block.chainid)))));

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
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
        );

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
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
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
        );

        assertEq(1 ether, address(_calls).balance);
        assertEq(1 ether, leet.balance);
        assertEq(1 ether, alice.balance);
        assertEq(100, _counter.count());

        vm.expectRevert("At least one signature already used");
        _calls.multiCall(
            _callReqs, arraySingle(signHashAsMessage(signingPK, keccak256(abi.encode(_callReqs, block.chainid))))
        );
    }
}
