// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./SessionCallsStructs.sol";

library SessionCallsStorage {
    bytes32 private constant STORAGE_SLOT = keccak256("com.trymetafab.wallet.SessionCalls");

    struct FunctionInfo {
        /**
         * @dev Whether or not the function is a transfer function.
         */
        bool isTransfer;
        /**
         * @dev The number of bits in the calldata preceding the token ID.
         *  This does not include the function selector.
         */
        uint16 tokenIdCalldataBitOffset;
    }

    struct Layout {
        mapping(address => mapping(uint256 => SessionCallsStructs.Session)) sessions;
        mapping(address => uint256) nextSessionId;
    }

    function layout() internal pure returns (Layout storage _layout) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _layout.slot := slot
        }
    }

    error InsufficientNativeTokenAllowance(uint256 amount, uint256 allowance);
    error SessionExpired();
    error NoSessionStarted(address sender);
    error UnauthorizedSessionCall(address targetContract, bytes4 functionSelector);
    error InvalidERC20TransferFunctionSelector(bytes4 functionSelector);
    error UnknownERC1155TransferFunction(bytes4 functionSelector);
    error InvalidStartingERC20BalancesLength(uint256 startingFungibleTokenBalancesLength);
    error InsufficientAllowanceForERC721Transfer(address tokenAddress, uint256 tokenId);
    error InsufficientAllowanceForERC1155Transfer(address tokenAddress, uint256 tokenId, uint256 amount, uint256 allowance);
    error InsufficientAllowanceForERC20Transfer(address tokenAddress, uint256 amount, uint256 allowance);
}
