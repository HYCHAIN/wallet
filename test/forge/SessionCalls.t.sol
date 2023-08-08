// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";
import { SessionCallsStructs } from "contracts/modules/SessionCalls/SessionCallsStructs.sol";
import { CallsStructs } from "contracts/modules/Calls/CallsStructs.sol";
import { SessionCalls } from "contracts/modules/SessionCalls/SessionCalls.sol";

import { ERC20MockDecimals } from "test/forge/mocks/ERC20MockDecimals.sol";

import "forge-std/console.sol";

contract SessionCallsImpl is SessionCalls {
    bool public didSomething;

    function initialize(address _controller) public initializer {
        __SessionCalls_init(_controller);
    }
}

contract RandomContract {
    uint256 public count;
    uint256 public countToken;

    function increment(uint256 _amount) public {
        count += _amount;
    }

    function spend() public payable {
        countToken += msg.value;
    }

    function spendERC20(address _ercAddress, uint256 _amount) public {
        countToken += _amount;
        ERC20MockDecimals(_ercAddress).transferFrom(msg.sender, address(this), _amount);
    }
}

contract SessionCallsTest is TestBase {
    SessionCallsImpl _calls;
    RandomContract _contract;

    ERC20MockDecimals _erc20 = new ERC20MockDecimals(18);

    uint256 internal nonceCur = 0;

    function setUp() public {
        _calls = SessionCallsImpl(proxify(address(new SessionCallsImpl())));
        _calls.initialize(signingAuthority);

        _contract = new RandomContract();
    }

    function testAllowStartSessionWithConsensus() public {
        uint256 exp = (block.timestamp + 1 days);
        SessionCallsStructs.SessionRequest memory req = createEmptySessionRequest();

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.startSession(
            leet,
            req,
            exp,
            nonceCur,
            new bytes[](0)
        );

        startSession(
            address(_calls),
            signingPK,
            leet,
            req,
            exp,
            ++nonceCur
        );

        assertTrue(_calls.hasActiveSession(leet));
    }

    function testAllowEndingActiveSessionWithConsensus() public {
        startSession(
            address(_calls),
            signingPK,
            leet,
            createEmptySessionRequest(),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.endSessionForCaller(leet, nonceCur, new bytes[](0));

        bytes memory sig = signHashAsMessage(
            signingPK,
            keccak256(abi.encode(leet, ++nonceCur, block.chainid))
        );
        _calls.endSessionForCaller(leet, nonceCur, arraySingle(sig));

        assertFalse(_calls.hasActiveSession(leet));
    }

    function testAllowDelegateEndSession() public {
        startSession(
            address(_calls),
            signingPK,
            leet,
            createEmptySessionRequest(),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        vm.prank(leet);
        _calls.endSession();

        assertFalse(_calls.hasActiveSession(leet));
    }

    /**
     * Call Tests
     */

    function testRevertNoSession() public {
        CallsStructs.CallRequest[] memory reqs = new CallsStructs.CallRequest[](1);
        reqs[0] = CallsStructs.CallRequest({
            target: address(_contract),
            value: 0,
            data: abi.encodeWithSelector(RandomContract.increment.selector, 1),
            nonce: ++nonceCur
        });
        vm.expectRevert("No sessions for sender");
        _calls.sessionCall(reqs[0]);

        vm.expectRevert("No sessions for sender");
        _calls.sessionMultiCall(reqs);
    }

    function testAllowGasTokenSpend() public {
        vm.deal(address(_calls), 10 ether);
        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(1 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        assertEq(10 ether, address(_calls).balance);

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 1 ether,
            data: abi.encodeWithSelector(RandomContract.spend.selector),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        vm.expectRevert("Value greater than allowance");
        _calls.sessionCall(_callReq);

        assertEq(9 ether, address(_calls).balance);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(2 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.expectRevert("Value greater than allowance");
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(7 ether, address(_calls).balance);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(2 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        CallsStructs.CallRequest[] memory reqs = new CallsStructs.CallRequest[](2);
        reqs[0] = _callReq;
        reqs[1] = _callReq;

        vm.prank(leet);
        _calls.sessionMultiCall(reqs);

        vm.expectRevert("Value greater than allowance");
        vm.prank(leet);
        _calls.sessionMultiCall(reqs);
        
        assertEq(5 ether, address(_calls).balance);
    }

    function testAllowERC20SpendThroughOtherContract() public {
        _erc20.mint(address(_calls), 10 ether);
        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_erc20), ERC20MockDecimals.approve.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeWithSelector(ERC20MockDecimals.approve.selector, address(_contract), 2 ether),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);
        
        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_contract), RandomContract.spendERC20.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        assertEq(10 ether, _erc20.balanceOf(address(_calls)));

        _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 0,
            data: abi.encodeWithSelector(RandomContract.spendERC20.selector, address(_erc20), 1 ether),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Multiple calls in the same session should be allowed
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(8 ether, _erc20.balanceOf(address(_calls)));
    }

    function testAllowERC20Spend() public {
        _erc20.mint(address(_calls), 10 ether);
        
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC20SpendSessionRequest(address(_erc20), 1 ether, address(_erc20), ERC20MockDecimals.transfer.selector),
            (block.timestamp + 1 days),
            ++nonceCur
        );

        assertEq(10 ether, _erc20.balanceOf(address(_calls)));

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeWithSelector(ERC20MockDecimals.transfer.selector, leet, 1 ether),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        vm.expectRevert("SessionCalls: ERC20 transfer exceeds allowance");
        _calls.sessionCall(_callReq);

        assertEq(9 ether, _erc20.balanceOf(address(_calls)));
        assertEq(1 ether, _erc20.balanceOf(leet));
    }
}
