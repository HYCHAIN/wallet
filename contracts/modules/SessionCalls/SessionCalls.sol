// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ISessionCalls.sol";
import "../Calls/Calls.sol";
import "./SessionCallsStorage.sol";

contract SessionCalls is Initializable, ISessionCalls, Calls {
    bytes4 private constant MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS = 0x0;

    constructor() {
        _disableInitializers();
    }

    function __SessionCalls_init(address _controller) internal onlyInitializing {
        __Calls_init(_controller);
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();

        _l.isRestrictedFunction[ERC20.increaseAllowance.selector] = true;
        _l.isRestrictedFunction[ERC20.decreaseAllowance.selector] = true;
        _l.isRestrictedFunction[IERC20.approve.selector] = true;
        _l.isRestrictedFunction[IERC721.approve.selector] = true;
        _l.isRestrictedFunction[IERC721.setApprovalForAll.selector] = true;
        _l.isRestrictedFunction[IERC1155.setApprovalForAll.selector] = true;

        _l.isERC20TransferFunction[ERC20.transfer.selector] = true;
        _l.isERC20TransferFunction[ERC20.transferFrom.selector] = true;
    }

    // start session
    function startSession(
        address _caller,
        SessionCallsStructs.SessionRequest calldata _sessionRequest,
        uint256 _expiresAt,
        uint256 _nonce,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(
            keccak256(abi.encode(_caller, _sessionRequest, _expiresAt, _nonce, block.chainid)),
            _signatures
        )
    {
        SessionCallsStructs.Session storage session =
            SessionCallsStorage.layout().sessions[_caller][SessionCallsStorage.layout().nextSessionId[_caller]];

        session.expiresAt = _expiresAt;

        // native token allowance
        session.allowances[address(0)][0] = _sessionRequest.nativeAllowance;

        for (uint256 i = 0; i < _sessionRequest.contractFunctionSelectors.length; i++) {
            for (uint256 j = 0; j < _sessionRequest.contractFunctionSelectors[i].functionSelectors.length; j++) {
                session.contractFunctionSelectors[_sessionRequest.contractFunctionSelectors[i].aContract][_sessionRequest
                    .contractFunctionSelectors[i].functionSelectors[j]] = true;
            }
        }

        for (uint256 i = 0; i < _sessionRequest.erc20Allowances.length; i++) {
            session.allowances[_sessionRequest.erc20Allowances[i].erc20Contract][0] =
                _sessionRequest.erc20Allowances[i].allowance;
        }

        for (uint256 i = 0; i < _sessionRequest.erc721Allowances.length; i++) {
            if (_sessionRequest.erc721Allowances[i].approveAll) {
                session.approveAlls[_sessionRequest.erc721Allowances[i].erc721Contract] = true;
            } else {
                for (uint256 j = 0; j < _sessionRequest.erc721Allowances[i].tokenIds.length; j++) {
                    session.allowances[_sessionRequest.erc721Allowances[i].erc721Contract][_sessionRequest
                        .erc721Allowances[i].tokenIds[j]] = 1;
                }
            }
        }

        for (uint256 i = 0; i < _sessionRequest.erc1155Allowances.length; i++) {
            if (_sessionRequest.erc1155Allowances[i].approveAll) {
                session.approveAlls[_sessionRequest.erc1155Allowances[i].erc1155Contract] = true;
            } else {
                for (uint256 j = 0; j < _sessionRequest.erc1155Allowances[i].tokenIds.length; j++) {
                    session.allowances[_sessionRequest.erc1155Allowances[i].erc1155Contract][_sessionRequest
                        .erc1155Allowances[i].tokenIds[j]] = _sessionRequest.erc1155Allowances[i].allowances[j];
                }
            }
        }

        SessionCallsStorage.layout().nextSessionId[_caller]++;
    }

    // end session
    function endSession() external {
        _endSessionForCaller(msg.sender);
    }

    function endSessionForCaller(
        address _caller,
        uint256 _nonce,
        bytes[] calldata _signatures
    ) external meetsControllersThreshold(keccak256(abi.encode(_caller, _nonce, block.chainid)), _signatures) {
        _endSessionForCaller(_caller);
    }

    // make session call
    function sessionCall(CallsStructs.CallRequest calldata _callRequest) public returns (bytes memory) {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        require(_l.nextSessionId[msg.sender] > 0, "No sessions for sender");
        SessionCallsStructs.Session storage session = _l.sessions[msg.sender][SessionCallsStorage
            .layout().nextSessionId[msg.sender] - 1];

        require(session.expiresAt > block.timestamp, "Session has ended or expired");
        require(_callRequest.value <= session.allowances[address(0)][0], "Value greater than allowance");

        // check if any function is approved for the target
        bytes4 functionSelector = bytes4(_callRequest.data);
        bool isApproved = session.contractFunctionSelectors[_callRequest.target][functionSelector];
        isApproved = isApproved
            || (
                session.contractFunctionSelectors[_callRequest.target][MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS]
                    && !_l.isRestrictedFunction[functionSelector]
            ); // require explicit approval for restricted functions when default all approved

        require(isApproved, "Call target or function not approved for this session.");

        bool _isERC20Transfer = _l.isERC20TransferFunction[functionSelector];
        uint256 _startingFungibleTokenBalance = 0;
        if(_isERC20Transfer) {
            // Can throw exceptions if the target is incorrectly set to a non-erc20 contract.
            _startingFungibleTokenBalance = IERC20(_callRequest.target).balanceOf(address(this));
        }

        // TODO: Working through handling allowance tracking & deductions from standard ERC func call & non-standard for 20/721/1155...
        // maybe...
        // erc721: only support allowance tracking for standard erc721 functions? Track ownership of id(s) before/after call of a standard func since we know what the id's involved are?
        // erc1155: only support allowance tracking for standard erc1155 functions? Track balance of id(s) before/after call of a standard func since we know what the id's involved are?

        bytes memory result = _call(_callRequest);

        // Check fungible token deductions against allowances if applicable.
        if(_isERC20Transfer) {
            uint256 _endingERC20Balance = IERC20(_callRequest.target).balanceOf(address(this));
            // If the balance of this wallet was reduced, check that the reduction was less than
            //  or equal to the session allowance.
            if(_endingERC20Balance <= _startingFungibleTokenBalance) {
                uint256 _erc20TransferAmount = _startingFungibleTokenBalance - _endingERC20Balance;
                require(_erc20TransferAmount <= session.allowances[_callRequest.target][0], "SessionCalls: ERC20 transfer exceeds allowance");
                session.allowances[_callRequest.target][0] -= _erc20TransferAmount;
            }
        }

        // Deduct any value from session allowance.
        session.allowances[address(0)][0] -= _callRequest.value;

        return result;
    }

    function sessionMultiCall(CallsStructs.CallRequest[] calldata _callRequests) external returns (bytes[] memory) {
        bytes[] memory results = new bytes[](_callRequests.length);

        for (uint256 i = 0; i < _callRequests.length; i++) {
            results[i] = sessionCall(_callRequests[i]);
        }

        return results;
    }

    function hasActiveSession(address _caller)
        external
        view
        returns (bool hasSession_)
    {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        if(_l.nextSessionId[_caller] == 0) {
            return false;
        }
        SessionCallsStructs.Session storage session = _l.sessions[_caller][_l.nextSessionId[_caller] - 1];
        return session.expiresAt > block.timestamp;
    }

    function _endSessionForCaller(address _caller) private {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        require(_l.nextSessionId[_caller] > 0, "No sessions for sender");
        _l.sessions[_caller][_l.nextSessionId[_caller] - 1]
            .expiresAt = 0;
    }
}
