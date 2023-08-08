// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { SessionCallsStructs } from "contracts/modules/SessionCalls/SessionCallsStructs.sol";
import { SessionCalls } from "contracts/modules/SessionCalls/SessionCalls.sol";
import { TestUtilities } from "test/forge/utils/TestUtilities.sol";

abstract contract TestSessionUtilities is TestUtilities {
    function createEmptySessionRequest() internal pure returns (SessionCallsStructs.SessionRequest memory) {
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0 ether,
            contractFunctionSelectors: new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](0),
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createRestrictedSessionRequest(address sessionContract, bytes4 functionSelector) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: sessionContract,
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

    function createGasSpendSessionRequest(uint amount, address sessionContract, bytes4 functionSelector) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: sessionContract,
            functionSelectors: functions
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: amount,
            contractFunctionSelectors: selectors,
            erc20Allowances: new SessionCallsStructs.SessionRequest_ERC20Allowance[](0),
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    function createERC20SpendSessionRequest(address ercAddress, uint amount, address sessionContract, bytes4 functionSelector) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](1);
        bytes4[] memory functions = new bytes4[](1);
        functions[0] = functionSelector;
        selectors[0] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
            aContract: sessionContract,
            functionSelectors: functions
        });
        SessionCallsStructs.SessionRequest_ERC20Allowance[] memory erc20Allowances =
            new SessionCallsStructs.SessionRequest_ERC20Allowance[](1);
        erc20Allowances[0] = SessionCallsStructs.SessionRequest_ERC20Allowance({
            erc20Contract: ercAddress,
            allowance: amount
        });
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: 0,
            contractFunctionSelectors: selectors,
            erc20Allowances: erc20Allowances,
            erc721Allowances: new SessionCallsStructs.SessionRequest_ERC721Allowance[](0),
            erc1155Allowances: new SessionCallsStructs.SessionRequest_ERC1155Allowance[](0)
        });
    }

    /**
     * @dev Assumes that each contract will invoke 1 function selector
     */
    function createGasSpendSessionRequestMulti(uint amount, address[] memory sessionContracts, bytes4[] memory functionSelectors) internal pure returns (SessionCallsStructs.SessionRequest memory) {
        require(sessionContracts.length == functionSelectors.length, "Session contract function length mismatch");
        SessionCallsStructs.SessionRequest_ContractFunctionSelectors[] memory selectors =
            new SessionCallsStructs.SessionRequest_ContractFunctionSelectors[](sessionContracts.length);
        for (uint i = 0; i < sessionContracts.length; i++) {    
            bytes4[] memory functions = new bytes4[](1);
            functions[i] = functionSelectors[i];
            selectors[i] = SessionCallsStructs.SessionRequest_ContractFunctionSelectors({
                aContract: sessionContracts[i],
                functionSelectors: functions
            });
        }
        return SessionCallsStructs.SessionRequest({
            nativeAllowance: amount,
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
        uint256 nonce
    ) internal {
        bytes memory sig =
            signHashAsMessage(signingPK, keccak256(abi.encode(delegateAddress, req, exp, nonce, block.chainid)));
        SessionCalls(sessionCalls).startSession(delegateAddress, req, exp, nonce, arraySingle(sig));
    }
}
