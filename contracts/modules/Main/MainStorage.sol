// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hychain.com
//
pragma solidity 0.8.23;

library MainStorage {
    bytes32 private constant STORAGE_SLOT = keccak256("com.trymetafab.wallet.Main");

    error UnauthorizedUpgrade();

    struct Layout {
        /**
         * @dev a transient value to indicate that controller threshold has been reached.
         */
        bool canUpgrade;
    }

    function layout() internal pure returns (Layout storage _layout) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _layout.slot := slot
        }
    }
}
