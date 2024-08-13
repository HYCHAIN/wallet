// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { SessionCallsStructs } from "contracts/modules/SessionCalls/SessionCallsStructs.sol";
import { SessionCalls } from "contracts/modules/SessionCalls/SessionCalls.sol";
import { TestUtilities } from "test/forge/utils/TestUtilities.sol";

abstract contract TestSessionUtilities is TestUtilities {
    bytes4 internal constant MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS = 0x00001337;
    address internal constant MAGIC_APPROVE_ALL_CONTRACT_ADDRESS = address(0x1337);

    function createEmptySessionRequest() internal pure returns (SessionCallsStructs.SessionRequest memory) {
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0 ether,
            contractFunctionSelectors: new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](0),
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createRestrictedSessionRequest(
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = _functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: functions
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createGasSpendSessionRequest(
        uint256 _amount,
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = _functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: functions
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: _amount,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createERC20SpendSessionRequest(
        address _ercAddress,
        uint256 _amount,
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = _functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: functions
        });
        SessionCallsStructs.SessionRequest_ERC20Allowance[] memory erc20Allowances =
            new SessionCallsStructs.SessionRequest_ERC20Allowance[](1);
        erc20Allowances[0] =
            SessionCallsStructs.SessionRequest_ERC20Allowance({ erc20Contract: _ercAddress, allowance: _amount });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: erc20Allowances,
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createAllContractsSessionRequest(bytes4 _functionSelector)
        internal
        pure
        returns (SessionCallsStructs.SessionRequest memory)
    {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = _functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: MAGIC_APPROVE_ALL_CONTRACT_ADDRESS,
            functionSelectors: functions
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createAllContractsAllFunctionsSessionRequest()
        internal
        pure
        returns (SessionCallsStructs.SessionRequest memory)
    {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: MAGIC_APPROVE_ALL_CONTRACT_ADDRESS,
            functionSelectors: functions
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createERC1155SpendSessionRequest(
        address _ercAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: asSingletonArray(_functionSelector)
        });
        SessionCallsStructs.SessionRequest_ERC1155Allowance[] memory erc1155Allowances =
            new SessionCallsStructs.SessionRequest_ERC1155Allowance[](1);
        erc1155Allowances[0] = SessionCallsStructs.SessionRequest_ERC1155Allowance({
            erc1155Contract: _ercAddress,
            approveAll: false,
            tokenIds: asSingletonArray(_tokenId),
            allowances: asSingletonArray(_amount)
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: erc1155Allowances
        });
    }

    function createERC1155SpendSessionRequest(
        address _ercAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: asSingletonArray(_functionSelector)
        });
        SessionCallsStructs.SessionRequest_ERC1155Allowance[] memory erc1155Allowances =
            new SessionCallsStructs.SessionRequest_ERC1155Allowance[](1);
        erc1155Allowances[0] = SessionCallsStructs.SessionRequest_ERC1155Allowance({
            erc1155Contract: _ercAddress,
            approveAll: false,
            tokenIds: _tokenIds,
            allowances: _amounts
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: erc1155Allowances
        });
    }

    function createERC721TransferSessionRequest(
        address _ercAddress,
        uint256 _tokenId,
        address _sessionContract,
        bytes4 _functionSelector
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: _sessionContract,
            functionSelectors: asSingletonArray(_functionSelector)
        });
        SessionCallsStructs.SessionRequest_ERC721Allowance[] memory erc721Allowances =
            new SessionCallsStructs.SessionRequest_ERC721Allowance[](1);
        erc721Allowances[0] = SessionCallsStructs.SessionRequest_ERC721Allowance({
            erc721Contract: _ercAddress,
            approveAll: false,
            tokenIds: asSingletonArray(_tokenId)
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: erc721Allowances,
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    /**
     * @dev Assumes that each contract will invoke 1 function selector
     */
    function createGasSpendSessionRequestMulti(
        uint256 _amount,
        address[] memory sessionContracts,
        bytes4[] memory functionSelectors
    ) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        require(sessionContracts.length == functionSelectors.length, "Session contract function length mismatch");
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](sessionContracts.length);
        for (uint256 i = 0; i < sessionContracts.length; i++) {
            bytes4[] memory functions = new bytes4[](1);
            functions[i] = functionSelectors[i];
            selectors[i] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
                aContract: sessionContracts[i],
                functionSelectors: functions
            });
        }
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: _amount,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function startSession(
        address sessionCalls,
        uint256 signingPK,
        address delegateAddress,
        SessionCallsStructs.SessionRequest memory req,
        uint256 exp,
        uint256 nonce,
        uint256 _deadline
    ) internal {
        bytes memory sig = signHashAsMessage(
            signingPK, keccak256(abi.encode(delegateAddress, req, exp, nonce, _deadline, block.chainid))
        );
        SessionCalls(sessionCalls).startSession(delegateAddress, req, exp, nonce, arraySingle(sig), 9999999);
    }
}
