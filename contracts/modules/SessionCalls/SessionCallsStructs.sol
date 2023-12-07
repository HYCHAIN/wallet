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

library SessionCallsStructs {
    struct SessionRequest {
        uint256 nativeAllowance; // native token allowance (e.g. eth, matic, etc)
        SessionRequest_ContractFunctionSelectors[] contractFunctionSelectors;
        SessionRequest_ERC20Allowance[] erc20Allowances;
        SessionRequest_ERC721Allowance[] erc721Allowances;
        SessionRequest_ERC1155Allowance[] erc1155Allowances;
    }

    struct SessionRequest_ContractFunctionSelectors {
        address aContract;
        bytes4[] functionSelectors;
    }

    struct SessionRequest_ERC20Allowance {
        address erc20Contract;
        uint256 allowance;
    }

    struct SessionRequest_ERC721Allowance {
        address erc721Contract;
        bool approveAll;
        uint256[] tokenIds;
    }

    struct SessionRequest_ERC1155Allowance {
        address erc1155Contract;
        bool approveAll;
        uint256[] tokenIds;
        uint256[] allowances;
    }

    /**
     * @dev We use a compact mapping to set allowances for different token types.
     * This currently includes native token, erc20, erc721 and erc1155 allowances.
     *
     * native token allowance mapping:  allowances[address(0)][0]
     * erc20 token allowance mapping:   allowances[erc20ContractAddress][0]
     * erc721 token allowance mapping:  allowances[erc721ContractAddress][tokenId] = 1
     * erc1155 token allowance mapping: allowances[erc1155ContractAddress][tokenId] = tokenIdAllowance
     */

    struct Session {
        uint256 expiresAt;
        mapping(address => mapping(bytes4 => bool)) contractFunctionSelectors;
        mapping(address => mapping(uint256 => uint256)) allowances;
        mapping(address => bool) approveAlls;
    }
}
