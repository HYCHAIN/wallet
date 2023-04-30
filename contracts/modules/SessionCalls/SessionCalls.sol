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
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
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

        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[ERC20.increaseAllowance.selector] = true;
        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[ERC20.decreaseAllowance.selector] = true;
        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[IERC20.approve.selector] = true;
        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[IERC721.approve.selector] = true;
        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[IERC721.setApprovalForAll.selector] = true;
        SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[IERC1155.setApprovalForAll.selector] = true;
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
        require(SessionCallsStorage.layout().nextSessionId[msg.sender] > 0, "No sessions for sender");
        SessionCallsStructs.Session storage session = SessionCallsStorage.layout().sessions[msg.sender][SessionCallsStorage
            .layout().nextSessionId[msg.sender] - 1];

        require(session.expiresAt > block.timestamp, "Session has ended or expired");

        // check if any function is approved for the target
        (bytes4 functionSelector, bytes memory abiEncodedData) = abi.decode(_callRequest.data, (bytes4, bytes));
        bool isApproved = session.contractFunctionSelectors[_callRequest.target][functionSelector];
        isApproved = isApproved
            || (
                session.contractFunctionSelectors[_callRequest.target][MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS]
                    && !SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[functionSelector]
            ); // require explicit approval for restricted functions when default all approved

        require(isApproved, "Call target or function not approved for this session.");

        // Value allowance check & deduction
        require(_callRequest.value <= session.allowances[address(0)][0], "Value greater than allowance");
        session.allowances[address(0)][0] -= _callRequest.value;

        // ERC20 allowance check & deduction
        if (IERC20(_callRequest.target).totalSupply() > 0) {
            uint256 amount;

            if (
                IERC20.transfer.selector == functionSelector ||
                IERC20.approve.selector == functionSelector ||
                ERC20.increaseAllowance.selector == functionSelector ||
                ERC20.decreaseAllowance.selector == functionSelector
            ) {
                (, amount) = abi.decode(abiEncodedData, (address, uint256));
            }

            if (IERC20.transferFrom.selector == functionSelector) {
                (, , amount) = abi.decode(abiEncodedData, (address, address, uint256));
            }

            require(amount <= session.allowances[_callRequest.target][0], "ERC20: Amount exceeds approval");
            session.allowances[_callRequest.target][0] -= amount;
        }

        // ERC721 allowance check & deduction
        if (IERC165(_callRequest.target).supportsInterface(type(IERC721).interfaceId) && !session.approveAlls[_callRequest.target]) {
            uint256 tokenId;

            if (IERC721.approve.selector == functionSelector) {
                (, tokenId) = abi.decode(abiEncodedData, (address, uint256));
            }

            if (
                bytes4(keccak256("safeTransferFrom(address,address,uint256)")) == functionSelector ||
                bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes")) == functionSelector ||
                IERC721.transferFrom.selector == functionSelector
            ) {
                (, , tokenId) = abi.decode(abiEncodedData, (address, address, uint256));
            }

            require(session.allowances[_callRequest.target][tokenId] == 1, "ERC721: TokenID not approved");
            session.allowances[_callRequest.target][tokenId] = 0;
        }

        // ERC1155 allowance check & deduction
        if (IERC165(_callRequest.target).supportsInterface(type(IERC1155).interfaceId)) { // ERC1155
            if (IERC1155.safeTransferFrom.selector == functionSelector) {
                (, , uint256 tokenId, uint256 amount) = abi.decode(abiEncodedData, (address, address, uint256, uint256));
                require(amount <= session.allowances[_callRequest.target][tokenId], "ERC1155: TokenID amount exceeds approval");
                session.allowances[_callRequest.target][tokenId] -= amount;
            }

            if (IERC1155.safeBatchTransferFrom.selector == functionSelector) {
                (, , uint256[] memory tokenIds, uint256[] memory amounts) = abi.decode(abiEncodedData, (address, address, uint256[], uint256[]));
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    require(session.allowances[_callRequest.target][tokenIds[i]] >= amounts[i], "ERC1155 TokenID amount exceeds approval");
                    session.allowances[_callRequest.target][tokenIds[i]] -= amounts[i];
                }
            }
        }

        bytes memory result = _call(_callRequest);

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
        if(SessionCallsStorage.layout().nextSessionId[_caller] == 0) {
            return false;
        }
        SessionCallsStructs.Session storage session = SessionCallsStorage.layout().sessions[_caller][SessionCallsStorage.layout().nextSessionId[_caller] - 1];
        return session.expiresAt > block.timestamp;
    }

    function _endSessionForCaller(address _caller) private {
        require(SessionCallsStorage.layout().nextSessionId[_caller] > 0, "No sessions for sender");
        SessionCallsStorage.layout().sessions[_caller][SessionCallsStorage.layout().nextSessionId[_caller] - 1]
            .expiresAt = 0;
    }
}
