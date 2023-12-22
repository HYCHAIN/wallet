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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ICalls, CallsStructs } from "contracts/interfaces/ICalls.sol";
import { Controllers } from "../Controllers/Controllers.sol";

abstract contract Calls is ICalls, Initializable, Controllers {
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @param _controller The address of the controller to add.
     */
    function __Calls_init(address _controller) internal onlyInitializing {
        __Controllers_init(_controller);
    }

    /**
     * @dev Execute a call.
     * @param _callRequest The call to execute
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function call(
        CallsStructs.CallRequest calldata _callRequest,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(keccak256(abi.encode(_callRequest, block.chainid)), _signatures)
        returns (bytes memory)
    {
        return _call(_callRequest);
    }

    /**
     * @dev Execute multiple calls at once.
     * @param _callRequests The calls to execute
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function multiCall(
        CallsStructs.CallRequest[] calldata _callRequests,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(keccak256(abi.encode(_callRequests, block.chainid)), _signatures)
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](_callRequests.length);

        for (uint256 i = 0; i < _callRequests.length; i++) {
            results[i] = _call(_callRequests[i]);
        }

        return results;
    }

    /**
     * @dev Check if the contract supports an interface.
     * @param interfaceId The interface ID to check for support.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Controllers) returns (bool) {
        if (interfaceId == type(ICalls).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _call(CallsStructs.CallRequest calldata _callRequest) internal returns (bytes memory) {
        (bool success, bytes memory result) = _callRequest.target.call{ value: _callRequest.value }(_callRequest.data);

        if (!success) {
            if (result.length == 0) {
                if (_callRequest.value > 0 && _callRequest.value > address(this).balance) {
                    revert("Insufficient funds to transfer");
                }
                revert("Call reverted without message");
            }
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }
}
