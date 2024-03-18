// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";
import { SessionCallsStructs } from "contracts/modules/SessionCalls/SessionCallsStructs.sol";
import { CallsStructs } from "contracts/modules/Calls/CallsStructs.sol";
import { SessionCalls, Calls, SessionCallsStorage } from "contracts/modules/SessionCalls/SessionCalls.sol";

import { ERC20MockDecimals } from "test/forge/mocks/ERC20MockDecimals.sol";
import { ERC1155Mock } from "test/forge/mocks/ERC1155Mock.sol";
import { ERC721Mock } from "test/forge/mocks/ERC721Mock.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "forge-std/console.sol";

contract SessionCallsImpl is SessionCalls, ERC1155Holder, ERC721Holder {
    bool public didSomething;

    function initialize(address _controller) public initializer {
        __SessionCalls_init(_controller);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Holder, SessionCalls) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract RandomContract is ERC1155Holder, ERC721Holder {
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

    function transferERC1155(address _ercAddress, uint256 _tokenId, uint256 _amount) public {
        countToken += _amount;
        ERC1155Mock(_ercAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
    }

    function transferERC721(address _ercAddress, uint256 _tokenId) public {
        countToken += 1;
        ERC721Mock(_ercAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function transferERC721To(address _ercAddress, uint256 _tokenId, address _to) public {
        countToken += 1;
        ERC721Mock(_ercAddress).safeTransferFrom(address(this), _to, _tokenId);
    }
}

contract SessionCallsTest is TestBase {
    bytes4 private constant SAFE_TRANSFER_FROM_SELECTOR1 =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant SAFE_TRANSFER_FROM_SELECTOR2 =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));

    uint256 _deadline = 9999999;

    SessionCallsImpl _calls;
    RandomContract _contract;

    ERC20MockDecimals _erc20 = new ERC20MockDecimals(18);
    ERC1155Mock _erc1155 = new ERC1155Mock();
    ERC721Mock _erc721 = new ERC721Mock();

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
        _calls.startSession(leet, req, exp, nonceCur, new bytes[](0), _deadline);

        startSession(address(_calls), signingPK, leet, req, exp, ++nonceCur, _deadline);

        assertTrue(_calls.hasActiveSession(leet));
    }

    function testAllowEndingActiveSessionWithConsensus() public {
        startSession(
            address(_calls),
            signingPK,
            leet,
            createEmptySessionRequest(),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        vm.expectRevert("Signer weights does not meet threshold");
        _calls.endSessionForCaller(leet, nonceCur, new bytes[](0), _deadline);

        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(leet, ++nonceCur, _deadline, block.chainid)));
        _calls.endSessionForCaller(leet, nonceCur, arraySingle(sig), _deadline);

        assertFalse(_calls.hasActiveSession(leet));
    }

    function testRevertEndingNonexistentSession() public {
        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(leet, ++nonceCur, _deadline, block.chainid)));

        vm.expectRevert(abi.encodeWithSelector(SessionCallsStorage.NoSessionStarted.selector, leet));
        _calls.endSessionForCaller(leet, nonceCur, arraySingle(sig), _deadline);
    }

    function testAllowDelegateEndSession() public {
        startSession(
            address(_calls),
            signingPK,
            leet,
            createEmptySessionRequest(),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
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
            data: abi.encodeCall(RandomContract.increment, (1)),
            nonce: ++nonceCur
        });
        vm.expectRevert(abi.encodeWithSelector(SessionCallsStorage.NoSessionStarted.selector, deployer));
        _calls.sessionCall(reqs[0]);

        vm.expectRevert(abi.encodeWithSelector(SessionCallsStorage.NoSessionStarted.selector, deployer));
        _calls.sessionMultiCall(reqs);
    }

    function testRevertSessionExpired() public {
        uint256 exp = (block.timestamp + 1 hours);
        SessionCallsStructs.SessionRequest memory req = createEmptySessionRequest();
        startSession(address(_calls), signingPK, leet, req, exp, ++nonceCur, _deadline);

        assertTrue(_calls.hasActiveSession(leet));
        vm.warp(exp + 1);
        assertFalse(_calls.hasActiveSession(leet));

        vm.prank(leet);
        vm.expectRevert(abi.encodeWithSelector(SessionCallsStorage.SessionExpired.selector));
        _calls.sessionCall(
            CallsStructs.CallRequest({
                target: address(_erc20),
                value: 0,
                data: abi.encodeCall(ERC20MockDecimals.decimals, ()),
                nonce: ++nonceCur
            })
        );
    }

    function testRevertUnauthorizedCalls() public {
        // _erc20.mint(address(_calls), 10 ether);
        // Start session for the `transfer` function on the erc20 contract
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC20SpendSessionRequest(
                address(_erc20), 1 ether, address(_erc20), ERC20MockDecimals.transfer.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        // Make call for unrelated function on erc20 contract
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.decimals, ()),
            nonce: ++nonceCur
        });

        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.UnauthorizedSessionCall.selector,
                address(_erc20),
                ERC20MockDecimals.decimals.selector
            )
        );
        _calls.sessionCall(_callReq);

        // Make call for `transfer` function on unrelated erc20 contract
        ERC20MockDecimals _erc20Other = new ERC20MockDecimals(18);
        _callReq = CallsStructs.CallRequest({
            target: address(_erc20Other),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.transfer, (leet, 1 ether)),
            nonce: ++nonceCur
        });

        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.UnauthorizedSessionCall.selector,
                address(_erc20Other),
                ERC20MockDecimals.transfer.selector
            )
        );
        _calls.sessionCall(_callReq);
    }

    /**
     * ERC20 Session Tests
     */

    function testAllowGasTokenSpend() public {
        vm.deal(address(_calls), 10 ether);
        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(1 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(10 ether, address(_calls).balance);

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 1 ether,
            data: abi.encodeCall(RandomContract.spend, ()),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(SessionCallsStorage.InsufficientNativeTokenAllowance.selector, 1 ether, 0)
        );
        _calls.sessionCall(_callReq);

        assertEq(9 ether, address(_calls).balance);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(2 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.expectRevert(
            abi.encodeWithSelector(SessionCallsStorage.InsufficientNativeTokenAllowance.selector, 1 ether, 0)
        );
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(7 ether, address(_calls).balance);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(2 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        CallsStructs.CallRequest[] memory reqs = new CallsStructs.CallRequest[](2);
        reqs[0] = _callReq;
        reqs[1] = _callReq;

        vm.prank(leet);
        _calls.sessionMultiCall(reqs);

        vm.expectRevert(
            abi.encodeWithSelector(SessionCallsStorage.InsufficientNativeTokenAllowance.selector, 1 ether, 0)
        );
        vm.prank(leet);
        _calls.sessionMultiCall(reqs);

        assertEq(5 ether, address(_calls).balance);

        // Start new session with .5 ether allowance to test a non-zero value allowance deficiency
        startSession(
            address(_calls),
            signingPK,
            leet,
            createGasSpendSessionRequest(0.5 ether, address(_contract), RandomContract.spend.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        vm.expectRevert(
            abi.encodeWithSelector(SessionCallsStorage.InsufficientNativeTokenAllowance.selector, 1 ether, 0.5 ether)
        );
        vm.prank(leet);
        _calls.sessionMultiCall(reqs);
    }

    function testAllowERC20SpendThroughOtherContract() public {
        _erc20.mint(address(_calls), 10 ether);
        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_erc20), ERC20MockDecimals.approve.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.approve, (address(_contract), 2 ether)),
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
            ++nonceCur,
            _deadline
        );

        assertEq(10 ether, _erc20.balanceOf(address(_calls)));

        _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 0,
            data: abi.encodeCall(RandomContract.spendERC20, (address(_erc20), 1 ether)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Multiple calls in the same session should be allowed
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(8 ether, _erc20.balanceOf(address(_calls)));
    }

    function testAllowERC20SpendDirect() public {
        _erc20.mint(address(_calls), 10 ether);

        // ERC20.transfer test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC20SpendSessionRequest(
                address(_erc20), 1 ether, address(_erc20), ERC20MockDecimals.transfer.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(10 ether, _erc20.balanceOf(address(_calls)));

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.transfer, (leet, 1 ether)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC20Transfer.selector, address(_erc20), 1 ether, 0
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(9 ether, _erc20.balanceOf(address(_calls)));
        assertEq(1 ether, _erc20.balanceOf(leet));

        // ERC20.transferFrom test
        // Must approve first, even though we are transfering from ourelves.
        // This is because the ERC20 standard didn't have the owner bypass that ERC721s have with transferFrom
        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_erc20), ERC20MockDecimals.approve.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );
        _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.approve, (address(_calls), 1 ether)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Start transferFrom session
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC20SpendSessionRequest(
                address(_erc20), 1 ether, address(_erc20), ERC20MockDecimals.transferFrom.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        _callReq = CallsStructs.CallRequest({
            target: address(_erc20),
            value: 0,
            data: abi.encodeCall(ERC20MockDecimals.transferFrom, (address(_calls), leet, 1 ether)),
            nonce: ++nonceCur
        });

        // Call transferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Try to call again without the required allowance
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC20Transfer.selector, address(_erc20), 1 ether, 0
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(8 ether, _erc20.balanceOf(address(_calls)));
        assertEq(2 ether, _erc20.balanceOf(leet));
    }

    function testCouldBeERC20() public {
        debug("Is ERC20: ", _couldBeERC20(address(_erc20)));
        _erc20.mint(deployer, 10 ether);
        debug("Is ERC20: ", _couldBeERC20(address(_erc20)));
        debug("Is deployer ERC20: ", _couldBeERC20(address(this)));
        debug("Is leet ERC20: ", _couldBeERC20(leet));
    }

    function balanceOf(address) public pure returns (uint256) {
        return 0;
    }

    function totalSupply() public pure returns (uint256) {
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function _couldBeERC20(address _targetContract) private view returns (bool couldBeERC20_) {
        (bool _success, bytes memory _returnData) =
            _targetContract.staticcall(abi.encodeCall(IERC20.balanceOf, (address(this))));
        couldBeERC20_ = _success && _returnData.length == 32;
        if (couldBeERC20_) {
            // If the contract has balanceOf AND totalSupply, it's definitely a token contract of some sort.
            (_success, _returnData) = _targetContract.staticcall(abi.encodeCall(IERC20.totalSupply, ()));
            couldBeERC20_ = _success && _returnData.length == 32;
            if (couldBeERC20_) {
                // If the contract has balanceOf AND totalSupply, and does not support ERC721/ERC1155, it's likely an ERC20
                if (_supportsInterface(_targetContract, type(IERC721).interfaceId)) {
                    return false; // If it supports ERC721, it's not an ERC20
                }
                if (_supportsInterface(_targetContract, type(IERC1155).interfaceId)) {
                    return false; // If it supports ERC1155, it's not an ERC20
                }
            }
        }
    }

    /**
     * @dev Will not revert if called against a non-contract or contract that does not implement ERC165.
     * @param _targetContract The contract to check.
     * @param _interfaceId The interface to check for support.
     */
    function _supportsInterface(
        address _targetContract,
        bytes4 _interfaceId
    ) private view returns (bool isSupported_) {
        (bool _success, bytes memory _returnData) =
            _targetContract.staticcall(abi.encodeCall(IERC165.supportsInterface, (_interfaceId)));
        isSupported_ = _success && abi.decode(_returnData, (bool));
    }

    /**
     * ERC1155 Session Tests
     */

    function testAllowERC1155TransferDirect() public {
        uint256 _testTokenId = 12345;
        _erc1155.mint(address(_calls), _testTokenId, 10);

        // safeTransferFrom session test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC1155SpendSessionRequest(
                address(_erc1155), _testTokenId, 2, address(_erc1155), ERC1155Mock.safeTransferFrom.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(10, _erc1155.balanceOf(address(_calls), _testTokenId));

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc1155),
            value: 0,
            data: abi.encodeCall(ERC1155Mock.safeTransferFrom, (address(_calls), leet, _testTokenId, 2, "")),
            nonce: ++nonceCur
        });

        // Call safeTransferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Try to call safeTransferFrom again without required allowance
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC1155Transfer.selector,
                address(_erc1155),
                _testTokenId,
                2,
                0
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(8, _erc1155.balanceOf(address(_calls), _testTokenId));
        assertEq(2, _erc1155.balanceOf(leet, _testTokenId));

        // safeBatchTransferFrom session test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC1155SpendSessionRequest(
                address(_erc1155),
                asSingletonArray(_testTokenId),
                asSingletonArray(2),
                address(_erc1155),
                ERC1155Mock.safeBatchTransferFrom.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        _callReq = CallsStructs.CallRequest({
            target: address(_erc1155),
            value: 0,
            data: abi.encodeCall(
                ERC1155Mock.safeBatchTransferFrom,
                (address(_calls), leet, asSingletonArray(_testTokenId), asSingletonArray(2), "")
                ),
            nonce: ++nonceCur
        });

        // Call safeBatchTransferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        // Try to call safeBatchTransferFrom again without required allowance
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC1155Transfer.selector,
                address(_erc1155),
                _testTokenId,
                2,
                0
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(6, _erc1155.balanceOf(address(_calls), _testTokenId));
        assertEq(4, _erc1155.balanceOf(leet, _testTokenId));
    }

    function testAllowERC1155TransferThroughOtherContract() public {
        uint256 _testTokenId = 12345;
        _erc1155.mint(address(_calls), _testTokenId, 10);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_erc1155), ERC1155Mock.setApprovalForAll.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc1155),
            value: 0,
            data: abi.encodeCall(ERC1155Mock.setApprovalForAll, (address(_contract), true)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_contract), RandomContract.transferERC1155.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(10, _erc1155.balanceOf(address(_calls), _testTokenId));

        _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 0,
            data: abi.encodeCall(RandomContract.transferERC1155, (address(_erc1155), _testTokenId, 2)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(8, _erc1155.balanceOf(address(_calls), _testTokenId));
        assertEq(2, _erc1155.balanceOf(address(_contract), _testTokenId));

        // Multiple calls in the same session should be allowed
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(6, _erc1155.balanceOf(address(_calls), _testTokenId));
        assertEq(4, _erc1155.balanceOf(address(_contract), _testTokenId));
    }

    /**
     * ERC721 Session Tests
     */

    function testAllowERC721TransferDirect() public {
        uint256 _testTokenId = 12345;
        _erc721.mint(address(_calls), _testTokenId);

        // transferFrom session test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC721TransferSessionRequest(
                address(_erc721), _testTokenId, address(_erc721), ERC721Mock.transferFrom.selector
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc721),
            value: 0,
            data: abi.encodeCall(ERC721Mock.transferFrom, (address(_calls), leet, _testTokenId)),
            nonce: ++nonceCur
        });

        // Call transferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        // Try to call transferFrom again without required allowance and without the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        vm.prank(leet);
        _erc721.transferFrom(leet, address(_calls), _testTokenId);

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        // Try to call transferFrom again without required allowance and with the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);

        // safeTransferFrom (no bytes parameter - SAFE_TRANSFER_FROM_SELECTOR1) session test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC721TransferSessionRequest(
                address(_erc721), _testTokenId, address(_erc721), SAFE_TRANSFER_FROM_SELECTOR1
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        _callReq = CallsStructs.CallRequest({
            target: address(_erc721),
            value: 0,
            data: abi.encodeWithSelector(SAFE_TRANSFER_FROM_SELECTOR1, address(_calls), leet, _testTokenId),
            nonce: ++nonceCur
        });

        // Call safeTransferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        // Try to call safeTransferFrom again without required allowance and without the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        vm.prank(leet);
        _erc721.transferFrom(leet, address(_calls), _testTokenId);

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        // Try to call safeTransferFrom again without required allowance and with the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);

        // safeTransferFrom (with bytes parameter - SAFE_TRANSFER_FROM_SELECTOR2) session test
        startSession(
            address(_calls),
            signingPK,
            leet,
            createERC721TransferSessionRequest(
                address(_erc721), _testTokenId, address(_erc721), SAFE_TRANSFER_FROM_SELECTOR2
            ),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        _callReq = CallsStructs.CallRequest({
            target: address(_erc721),
            value: 0,
            data: abi.encodeWithSelector(SAFE_TRANSFER_FROM_SELECTOR2, address(_calls), leet, _testTokenId, ""),
            nonce: ++nonceCur
        });

        // Call safeTransferFrom
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        // Try to call safeTransferFrom again without required allowance and without the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);

        assertEq(leet, _erc721.ownerOf(_testTokenId));

        vm.prank(leet);
        _erc721.transferFrom(leet, address(_calls), _testTokenId);

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        // Try to call safeTransferFrom again without required allowance and with the token
        vm.prank(leet);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionCallsStorage.InsufficientAllowanceForERC721Transfer.selector, address(_erc721), _testTokenId
            )
        );
        _calls.sessionCall(_callReq);
    }

    function testAllowERC721TransferThroughOtherContract() public {
        uint256 _testTokenId = 12345;
        _erc721.mint(address(_calls), _testTokenId);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_erc721), ERC721Mock.setApprovalForAll.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );
        CallsStructs.CallRequest memory _callReq = CallsStructs.CallRequest({
            target: address(_erc721),
            value: 0,
            data: abi.encodeCall(ERC721Mock.setApprovalForAll, (address(_contract), true)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        startSession(
            address(_calls),
            signingPK,
            leet,
            createRestrictedSessionRequest(address(_contract), RandomContract.transferERC721.selector),
            (block.timestamp + 1 days),
            ++nonceCur,
            _deadline
        );

        assertEq(address(_calls), _erc721.ownerOf(_testTokenId));

        _callReq = CallsStructs.CallRequest({
            target: address(_contract),
            value: 0,
            data: abi.encodeCall(RandomContract.transferERC721, (address(_erc721), _testTokenId)),
            nonce: ++nonceCur
        });
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(address(_contract), _erc721.ownerOf(_testTokenId));

        _contract.transferERC721To(address(_erc721), _testTokenId, address(_calls));

        // Multiple calls in the same session should be allowed
        vm.prank(leet);
        _calls.sessionCall(_callReq);

        assertEq(address(_contract), _erc721.ownerOf(_testTokenId));
    }
}
