// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//
pragma solidity 0.8.23;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "contracts/interfaces/ISessionCalls.sol";
import "../Calls/Calls.sol";
import "./SessionCallsStorage.sol";

contract SessionCalls is Initializable, ISessionCalls, Calls {
    bytes4 private constant MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS = 0x0;
    bytes4 private constant SAFE_TRANSFER_FROM_SELECTOR1 =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant SAFE_TRANSFER_FROM_SELECTOR2 =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));

    /**
     * @dev Disables initializations for any implementation contracts deployed.
     */
    constructor() {
        _disableInitializers();
    }

    function __SessionCalls_init(address _controller) internal onlyInitializing {
        __Calls_init(_controller);
    }

    /**
     *
     * @param _caller The caller to start the session for.
     * @param _sessionRequest The request payload for the session to be started.
     * @param _expiresAt The epoch of when the session should expire.
     * @param _nonce The nonce of the signatures to verify against for authorization.
     * @param _signatures The signatures of the controller(s) authorizing the session start.
     */
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

        // Native token allowance is stored at index 0 of address(0) in allowances mapping.
        // See {SessionCallsStructs.Session} for more info.
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

    /**
     * @dev Ends the session for the sender of this call. No authorization required, since it's "their" session to end.
     */
    function endSession() external {
        _endSessionForCaller(msg.sender);
    }

    /**
     * @dev Ends a session for a caller. Needs sufficient controller authorization via signatures.
     * @param _caller The caller to end the session for.
     * @param _nonce The nonce of the signatures to verify against for authorization.
     * @param _signatures The signatures of the controller(s) authorizing the session end.
     */
    function endSessionForCaller(
        address _caller,
        uint256 _nonce,
        bytes[] calldata _signatures
    ) external meetsControllersThreshold(keccak256(abi.encode(_caller, _nonce, block.chainid)), _signatures) {
        _endSessionForCaller(_caller);
    }

    /**
     * @dev Invokes a call in a session. The caller must have an active session, the session must not be expired,
     *  the target must be approved, and the caller must have sufficient allowance for the call if applicable.
     * @param _callRequest The request payload for the call to be invoked.
     */
    function sessionCall(CallsStructs.CallRequest calldata _callRequest) public returns (bytes memory) {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        if (_l.nextSessionId[msg.sender] == 0) {
            revert SessionCallsStorage.NoSessionStarted(msg.sender);
        }
        SessionCallsStructs.Session storage session =
            _l.sessions[msg.sender][SessionCallsStorage.layout().nextSessionId[msg.sender] - 1];

        if (session.expiresAt <= block.timestamp) {
            revert SessionCallsStorage.SessionExpired();
        }
        if (_callRequest.value > session.allowances[address(0)][0]) {
            revert SessionCallsStorage.InsufficientNativeTokenAllowance(
                _callRequest.value, session.allowances[address(0)][0]
            );
        }

        // Check if the the given function is approved for the target in this session.
        bytes4 _functionSelector = bytes4(_callRequest.data);
        if (!_isFunctionApprovedForSession(session, _callRequest.target, _functionSelector)) {
            revert SessionCallsStorage.UnauthorizedSessionCall(_callRequest.target, _functionSelector);
        }

        _deductERC20AllowancesIfNeeded(session, _callRequest, _functionSelector);
        _deductERC1155AllowancesIfNeeded(session, _callRequest, _functionSelector);
        _deductERC721AllowancesIfNeeded(session, _callRequest, _functionSelector);

        // Deduct any value from session allowance.
        // Do this before invoking the call incase the call has reentrancy that would allow the call to spend more than the allowance.
        session.allowances[address(0)][0] -= _callRequest.value;

        return _call(_callRequest);
    }

    /**
     * @dev Invokes multiple calls in a single transaction. All must succeed for the transaction to succeed.
     * @param _callRequests The request payload for each call to be invoked.
     */
    function sessionMultiCall(CallsStructs.CallRequest[] calldata _callRequests) external returns (bytes[] memory) {
        bytes[] memory results = new bytes[](_callRequests.length);

        for (uint256 i = 0; i < _callRequests.length; i++) {
            results[i] = sessionCall(_callRequests[i]);
        }

        return results;
    }

    /**
     * @dev Checks if the caller has an active session and can make session calls.
     * @param _caller The caller to check for an active session.
     * @return hasSession_ True if the caller has an active session, false otherwise.
     */
    function hasActiveSession(address _caller) external view returns (bool hasSession_) {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        if (_l.nextSessionId[_caller] == 0) {
            return false;
        }
        SessionCallsStructs.Session storage session = _l.sessions[_caller][_l.nextSessionId[_caller] - 1];
        return session.expiresAt > block.timestamp;
    }

    function _endSessionForCaller(address _caller) private {
        SessionCallsStorage.Layout storage _l = SessionCallsStorage.layout();
        if (_l.nextSessionId[_caller] == 0) {
            revert SessionCallsStorage.NoSessionStarted(_caller);
        }
        _l.sessions[_caller][_l.nextSessionId[_caller] - 1].expiresAt = 0;
    }

    /**
     * @dev Checks if the function is a transfer function, and if so, verifies that there is sufficient session allowance for the transfer,
     *  and deducts the token amount from the session allowance.
     * @param session The session to check.
     * @param _callRequest The request payload for the call.
     * @param _functionSelector The function for the target contract being called.
     */
    function _deductERC20AllowancesIfNeeded(
        SessionCallsStructs.Session storage session,
        CallsStructs.CallRequest calldata _callRequest,
        bytes4 _functionSelector
    ) private {
        if (_functionSelector == ERC20.transfer.selector) {
            if (!_couldBeERC20(_callRequest.target)) {
                // It couldn't be an ERC20 contract, so we don't need to check allowances.
                // It could be an ERC721, since they both have the `transferFrom` function.
                return;
            }

            (, uint256 _amount) = abi.decode(_callRequest.data[4:], (address, uint256));

            if (session.allowances[_callRequest.target][0] < _amount) {
                revert SessionCallsStorage.InsufficientAllowanceForERC20Transfer(
                    _callRequest.target, _amount, session.allowances[_callRequest.target][0]
                );
            }

            session.allowances[_callRequest.target][0] -= _amount;
        } else if (_functionSelector == ERC20.transferFrom.selector) {
            if (!_couldBeERC20(_callRequest.target)) {
                // It couldn't be an ERC20 contract, so we don't need to check allowances.
                return;
            }
            (,, uint256 _amount) = abi.decode(_callRequest.data[4:], (address, address, uint256));

            if (session.allowances[_callRequest.target][0] < _amount) {
                revert SessionCallsStorage.InsufficientAllowanceForERC20Transfer(
                    _callRequest.target, _amount, session.allowances[_callRequest.target][0]
                );
            }

            session.allowances[_callRequest.target][0] -= _amount;
        }
    }

    /**
     * @dev Checks if the function is a transfer function, and if so, verifies that there is sufficient session allowance(s) for all tokenId(s),
     *  and deducts the token amount(s) from the session allowance(s).
     * @param session The session to check.
     * @param _callRequest The request payload for the call.
     * @param _functionSelector The function for the target contract being called.
     */
    function _deductERC1155AllowancesIfNeeded(
        SessionCallsStructs.Session storage session,
        CallsStructs.CallRequest calldata _callRequest,
        bytes4 _functionSelector
    ) private {
        if (_functionSelector == IERC1155.safeTransferFrom.selector) {
            if (!_supportsInterface(_callRequest.target, type(IERC1155).interfaceId)) {
                // Non-ERC1155 standard contract calling safeTransferFrom.
                return;
            }

            (,, uint256 _tokenId, uint256 _amount,) =
                abi.decode(_callRequest.data[4:], (address, address, uint256, uint256, bytes));

            if (session.allowances[_callRequest.target][_tokenId] < _amount) {
                revert SessionCallsStorage.InsufficientAllowanceForERC1155Transfer(
                    _callRequest.target, _tokenId, _amount, session.allowances[_callRequest.target][_tokenId]
                );
            }

            session.allowances[_callRequest.target][_tokenId] -= _amount;
        } else if (_functionSelector == IERC1155.safeBatchTransferFrom.selector) {
            if (!_supportsInterface(_callRequest.target, type(IERC1155).interfaceId)) {
                // Non-ERC1155 standard contract calling safeBatchTransferFrom.
                return;
            }

            (,, uint256[] memory _tokenIds, uint256[] memory _amounts,) =
                abi.decode(_callRequest.data[4:], (address, address, uint256[], uint256[], bytes));

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (session.allowances[_callRequest.target][_tokenIds[i]] < _amounts[i]) {
                    revert SessionCallsStorage.InsufficientAllowanceForERC1155Transfer(
                        _callRequest.target,
                        _tokenIds[i],
                        _amounts[i],
                        session.allowances[_callRequest.target][_tokenIds[i]]
                    );
                }

                session.allowances[_callRequest.target][_tokenIds[i]] -= _amounts[i];
            }
        }
    }

    /**
     * @dev Checks if the function is a transfer function, and if so, verifies that there is a session allowance for the tokenId,
     *  and uses the allowance if the session isn't approved for the entire collection.
     * @param session The session to check.
     * @param _callRequest The request payload for the call.
     * @param _functionSelector The function for the target contract being called.
     */
    function _deductERC721AllowancesIfNeeded(
        SessionCallsStructs.Session storage session,
        CallsStructs.CallRequest calldata _callRequest,
        bytes4 _functionSelector
    ) private {
        // Explicitly check approveAlls ONLY if the function is a transfer, otherwise there will always be a
        // gas overhead for checking that storage slot when not needed

        if (_functionSelector == IERC721.transferFrom.selector) {
            if (!_supportsInterface(_callRequest.target, type(IERC721).interfaceId)) {
                // Non-ERC721 standard contract calling transferFrom.
                // Could be an ERC20 contract, since both contracts have `transferFrom`
                return;
            }
            // If the session gave approval to the entire collection, allow the transfer. No allowance deductions needed.
            if (session.approveAlls[_callRequest.target]) {
                return;
            }

            (,, uint256 _tokenId) = abi.decode(_callRequest.data[4:], (address, address, uint256));

            // If there is no allowance for the token, revert.
            if (session.allowances[_callRequest.target][_tokenId] == 0) {
                revert SessionCallsStorage.InsufficientAllowanceForERC721Transfer(_callRequest.target, _tokenId);
            }

            session.allowances[_callRequest.target][_tokenId] = 0;
            // Solidity cannot differentiate function overloads using .selector, so we have to manually calculate the selector for safeTransferFrom
        } else if (_functionSelector == SAFE_TRANSFER_FROM_SELECTOR1) {
            if (!_supportsInterface(_callRequest.target, type(IERC721).interfaceId)) {
                // Non-ERC721 standard contract calling safeTransferFrom.
                return;
            }
            // If the session gave approval to the entire collection, allow the transfer. No allowance deductions needed.
            if (session.approveAlls[_callRequest.target]) {
                return;
            }

            (,, uint256 _tokenId) = abi.decode(_callRequest.data[4:], (address, address, uint256));

            // If there is no allowance for the token, revert.
            if (session.allowances[_callRequest.target][_tokenId] == 0) {
                revert SessionCallsStorage.InsufficientAllowanceForERC721Transfer(_callRequest.target, _tokenId);
            }

            session.allowances[_callRequest.target][_tokenId] = 0;
            // Solidity cannot differentiate function overloads using .selector, so we have to manually calculate the selector for safeTransferFrom
        } else if (_functionSelector == SAFE_TRANSFER_FROM_SELECTOR2) {
            if (!_supportsInterface(_callRequest.target, type(IERC721).interfaceId)) {
                // Non-ERC721 standard contract calling safeTransferFrom.
                return;
            }
            // If the session gave approval to the entire collection, allow the transfer. No allowance deductions needed.
            if (session.approveAlls[_callRequest.target]) {
                return;
            }

            (,, uint256 _tokenId,) = abi.decode(_callRequest.data[4:], (address, address, uint256, bytes));

            // If there is no allowance for the token, revert.
            if (session.allowances[_callRequest.target][_tokenId] == 0) {
                revert SessionCallsStorage.InsufficientAllowanceForERC721Transfer(_callRequest.target, _tokenId);
            }

            session.allowances[_callRequest.target][_tokenId] = 0;
        }
    }

    /**
     * @dev Checks if the given function is either explicitly approved for the session, or if the session has
     *  the MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS selector approved. If the function is a restricted function,
     *  the MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS selector is ignored
     * @param _session The session to check.
     * @param _targetContract The target contract being called.
     * @param _functionSelector The function for the target contract being called.
     */
    function _isFunctionApprovedForSession(
        SessionCallsStructs.Session storage _session,
        address _targetContract,
        bytes4 _functionSelector
    ) private view returns (bool isApproved_) {
        // Must have explicit approval for restricted functions even if default all approved
        isApproved_ = _session.contractFunctionSelectors[_targetContract][_functionSelector]
            || (
                _session.contractFunctionSelectors[_targetContract][MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS]
                    && !_isRestrictedFunction(_functionSelector)
            );
    }

    /**
     * @dev Check if the contract has a balanceOf and totalSupply function to determine if it's likely an ERC20.
     *  Because some extensions of ERC721 and ERC1155 implement these functions, we must also assert that this contract does
     *  not support those standards. We cannot assert that this contract supports ERC20, because the ERC20 standard does not implement
     *  ERC165's supportInterface function.
     * @param _targetContract The contract to check.
     * @return couldBeERC20_ True if the contract is probably an ERC20, false otherwise.
     */
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
     * @dev Private function vs state storage to allow for beacon updates to be made to all instances without
     *  needing to update state of each proxy
     * @param _functionSelector The function selector to check.
     */
    function _isRestrictedFunction(bytes4 _functionSelector) private pure returns (bool isRestricted_) {
        if (
            _functionSelector == IERC20.approve.selector || _functionSelector == IERC721.approve.selector
                || _functionSelector == IERC721.setApprovalForAll.selector
                || _functionSelector == IERC1155.setApprovalForAll.selector
        ) {
            isRestricted_ = true;
        }
    }
}
