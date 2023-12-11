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

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Calls } from "../Calls/Calls.sol";
import { Controllers } from "../Controllers/Controllers.sol";
import { ERC1271 } from "../ERC1271/ERC1271.sol";
import { Versioned } from "../Versioned/Versioned.sol";
import { PreauthorizedCalls } from "../PreauthorizedCalls/PreauthorizedCalls.sol";
import { MainStorage } from "./MainStorage.sol";
import { IMain } from "contracts/interfaces/IMain.sol";

contract Main is
    IMain,
    UUPSUpgradeable,
    Initializable,
    Versioned,
    PreauthorizedCalls,
    ERC1155Holder,
    ERC721Holder,
    ERC1271
{
    string public constant version = "alpha-1.0.0";

    /**
     * @dev Initialize the contract.
     * @param _controller The address of the controller to add.
     */
    function initialize(address _controller) external initializer {
        __Controllers_init(_controller);
    }

    /**
     * @dev Check if the contract supports an interface.
     * @param _interfaceID The interface ID to check for support.
     */
    function supportsInterface(bytes4 _interfaceID)
        public
        view
        override(PreauthorizedCalls, ERC1271, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(_interfaceID);
    }

    /**
     *
     * @dev Upgrade the implementation of the wallet contract. Must be called from the wallet's proxy and only when
     *      there is sufficient controlling signatures to meet the threshold.
     * @param newImplementation The address of the new logic contract for the proxy.
     * @param data Optional calldata to invoke against the implementation contract after upgrading.
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data,
        bytes[] calldata _signatures
    )
        external
        payable
        virtual
        onlyProxy
        meetsControllersThreshold(keccak256(abi.encode(newImplementation, data, block.chainid)), _signatures)
    {
        MainStorage.layout().canUpgrade = true;
        upgradeToAndCall(newImplementation, data);
        // Should already be set but just to be safe
        MainStorage.layout().canUpgrade = false;
    }

    function _authorizeUpgrade(address) internal override {
        if (!MainStorage.layout().canUpgrade) {
            revert MainStorage.UnauthorizedUpgrade();
        }
        MainStorage.layout().canUpgrade = false;
    }
}
