// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "./IERC1271.sol";
import "../Controllers/Controllers.sol";
import "../../utils/Bytes.sol";

abstract contract ERC1271 is IERC1271, Controllers {
    using Bytes for bytes;

    uint8 private constant SIGNATURE_BYTES_LENGTH = 65;

    bytes4 private constant ERC1271_MAGIC_BYTES_BYTES_SUCCESS = 0x20c13b0b;
    bytes4 private constant ERC1271_MAGIC_BYTES32_BYTES_SUCCESS = 0x1626ba7e;
    bytes4 private constant ERC1271_MAGIC_BYTES_FAILURE = 0x00000000;

    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue) {
      if (_validatePackedSignature(keccak256(_data), _signature)) {
        return ERC1271_MAGIC_BYTES_BYTES_SUCCESS;
      } else {
        return ERC1271_MAGIC_BYTES_FAILURE;
      }
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external override view returns (bytes4 magicValue) {
      if (_validatePackedSignature(_hash, _signature)) {
        return ERC1271_MAGIC_BYTES32_BYTES_SUCCESS;
      } else {
        return ERC1271_MAGIC_BYTES_FAILURE;
      }
    }

    function _validatePackedSignature(bytes32 _hash, bytes calldata _signature) private view returns (bool) {
      require(_signature.length % SIGNATURE_BYTES_LENGTH == 0, "Unexpected packaged signature byte length");
      uint256 totalSignatures = _signature.length / SIGNATURE_BYTES_LENGTH;
      bytes[] memory signatures = new bytes[](totalSignatures);

      for (uint256 i = 0; i < totalSignatures; i++) {
        signatures[i] = _signature.slice(i * SIGNATURE_BYTES_LENGTH, SIGNATURE_BYTES_LENGTH);
      }
      
      (bool verified, ) = verifyControllersThresholdBySignatures(_hash, signatures);

      return verified;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(Controllers) returns (bool) {
      if (interfaceId == type(IERC1271).interfaceId) {
        return true;
      }

      return super.supportsInterface(interfaceId);
    }
}