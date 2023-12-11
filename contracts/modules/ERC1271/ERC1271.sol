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

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "../Controllers/Controllers.sol";
import "../../utils/Bytes.sol";

abstract contract ERC1271 is IERC1271, Controllers {
    using Bytes for bytes;

    error InvalidSignatureLength();

    uint8 private constant SIGNATURE_BYTES_LENGTH = 65;

    bytes4 private constant ERC1271_MAGIC_BYTES_BYTES_SUCCESS = 0x20c13b0b;
    bytes4 private constant ERC1271_MAGIC_BYTES32_BYTES_SUCCESS = 0x1626ba7e;
    bytes4 private constant ERC1271_MAGIC_BYTES_FAILURE = 0x00000000;

    /**
     * @dev Returns whether the given signature is valid for the given data
     * @param _data Data to validate against the given signature
     * @param _signature Signature to verify against the given data
     * @return magicValue Magic value if the signature is valid for the given data, otherwise `bytes4(0)`.
     */
    function isValidSignature(
        bytes calldata _data,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue) {
        if (_validatePackedSignature(keccak256(_data), _signature)) {
            return ERC1271_MAGIC_BYTES_BYTES_SUCCESS;
        } else {
            return ERC1271_MAGIC_BYTES_FAILURE;
        }
    }

    /**
     * @dev Returns whether the given signature is valid for the given data hash
     * @param _hash Hashed data to validate against the given signature
     * @param _signature Signature to verify against the given data hash
     * @return magicValue Magic value if the signature is valid for the given hash, otherwise `bytes4(0)`.
     */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view override returns (bytes4 magicValue) {
        if (_validatePackedSignature(_hash, _signature)) {
            return ERC1271_MAGIC_BYTES32_BYTES_SUCCESS;
        } else {
            return ERC1271_MAGIC_BYTES_FAILURE;
        }
    }

    function _validatePackedSignature(bytes32 _hash, bytes calldata _signature) private view returns (bool) {
        if (_signature.length % SIGNATURE_BYTES_LENGTH != 0) {
            revert InvalidSignatureLength();
        }
        uint256 totalSignatures = _signature.length / SIGNATURE_BYTES_LENGTH;
        bytes[] memory signatures = new bytes[](totalSignatures);

        for (uint256 i = 0; i < totalSignatures; i++) {
            signatures[i] = _signature.slice(i * SIGNATURE_BYTES_LENGTH, SIGNATURE_BYTES_LENGTH);
        }

        (bool verified,) = _verifyControllersThresholdBySignatures(_hash, signatures);

        return verified;
    }

    /**
     * @dev Check if the contract supports an interface.
     * @param interfaceId Interface ID of the function to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Controllers) returns (bool) {
        if (interfaceId == type(IERC1271).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
