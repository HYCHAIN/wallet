// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//

pragma solidity 0.8.18;

library ControllersStorage {
    bytes32 private constant STORAGE_SLOT = keccak256("com.trymetafab.wallet.Controllers");

    struct Layout {
        uint256 threshold;
        uint256 totalWeights;
        mapping(address => uint256) weights;
        mapping(bytes32 => bool) usedSignatures;
    }

    function layout() internal pure returns (Layout storage _layout) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _layout.slot := slot
        }
    }
}
