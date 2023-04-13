// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Signatures {
    using ECDSA for bytes32;

    function getSigner(bytes32 _inputHash, bytes memory _signature) internal pure returns (address) {
        return _inputHash.toEthSignedMessageHash().recover(_signature);
    }

    function getSigners(bytes32 _inputHash, bytes[] memory _signatures) internal pure returns (address[] memory) {
        address[] memory addresses = new address[](_signatures.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            addresses[i] = getSigner(_inputHash, _signatures[i]);
        }

        return addresses;
    }
}
