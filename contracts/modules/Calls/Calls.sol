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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ICalls, CallsStructs } from "contracts/interfaces/ICalls.sol";
import { Controllers } from "../Controllers/Controllers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

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
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external returns (bytes memory) {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_callRequest, _deadline, block.chainid)), _deadline, _signatures
        );
        return _call(_callRequest);
    }

    /**
     * @dev Execute a call.
     * @param _createRequest The contract creation arguments to execute
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function create(
        CallsStructs.CreateRequest calldata _createRequest,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external returns (address) {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_createRequest, _deadline, block.chainid)), _deadline, _signatures
        );
        return _create(_createRequest);
    }

    /**
     * @dev Execute multiple calls at once.
     * @param _callRequests The calls to execute
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function multiCall(
        CallsStructs.CallRequest[] calldata _callRequests,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external returns (bytes[] memory) {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_callRequests, _deadline, block.chainid)), _deadline, _signatures
        );
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
                    revert InsufficientFunds();
                }
                revert RevertWithoutMessage();
            }
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    function _create(CallsStructs.CreateRequest calldata _createRequest) internal returns (address newContract_) {
        newContract_ = Create2.deploy(0, _createRequest.salt, _createRequest.bytecode);
        if (_createRequest.initCode.length > 0) {
            (bool _success, bytes memory _error) = newContract_.call(_createRequest.initCode);
            if (!_success) {
                if (_error.length > 0) {
                    // bubble up the _error
                    assembly {
                        revert(add(32, _error), mload(_error))
                    }
                } else {
                    revert CreateInitCodeFailed();
                }
            }
        }
    }
}
