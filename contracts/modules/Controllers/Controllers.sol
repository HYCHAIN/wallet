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
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IControllers } from "contracts/interfaces/IControllers.sol";
import { Signatures } from "../../utils/Signatures.sol";
import { ControllersStorage } from "./ControllersStorage.sol";

abstract contract Controllers is Initializable, IControllers, ERC165 {
    error InvalidThreshold();
    error DeadlineReached();
    error ThresholdImpossible();
    error ControllersNotInitialized();
    error ControllerDoesNotExist();
    error ControllerAlreadyExists();
    error ArraryLengthMismatch();
    error InvalidParameters();

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract.
     * @param _controller The address of the controller to add.
     */
    function __Controllers_init(address _controller) internal onlyInitializing {
        _addController(_controller, 1);
        ControllersStorage.layout().threshold = 1;
    }

    /**
     * @dev Add controllers to the contract.
     * @param _controllers The addresses of the controllers to add.
     * @param _weights The weights of the controllers to add.
     * @param _nonce A nonce to prevent replay attacks.
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function addControllers(
        address[] calldata _controllers,
        uint256[] calldata _weights,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_controllers, _weights, _nonce, _deadline, block.chainid)), _deadline, _signatures
        );
        if (_controllers.length != _weights.length) {
            revert ArraryLengthMismatch();
        }
        if (_controllers.length == 0) {
            revert InvalidParameters();
        }
        for (uint256 i = 0; i < _controllers.length; i++) {
            address _controller = _controllers[i];
            if (ControllersStorage.layout().weights[_controller] != 0) {
                revert ControllerAlreadyExists();
            }
            _addController(_controller, _weights[i]);
        }
    }

    /**
     * @dev Remove controllers from the contract. Also sets a new threshold if provided.
     * @param _controllers The addresses of the controllers to remove.
     * @param _newThreshold The new threshold required to invoke functions on the wallet.
     * @param _nonce A nonce to prevent replay attacks.
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function removeControllers(
        address[] calldata _controllers,
        uint256 _newThreshold,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_controllers, _newThreshold, _nonce, _deadline, block.chainid)), _deadline, _signatures
        );
        if (_controllers.length == 0) {
            revert InvalidParameters();
        }
        for (uint256 i = 0; i < _controllers.length; i++) {
            _removeController(_controllers[i]);
        }
        // update at the end to ensure new totalWeights has been calculated.
        if (_newThreshold != 0) {
            _updateThreshold(_newThreshold);
        }
    }

    function replaceController(
        address _controllerOld,
        address _controllerNew,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_controllerOld, _controllerNew, _nonce, _deadline, block.chainid)),
            _deadline,
            _signatures
        );
        if (ControllersStorage.layout().weights[_controllerOld] == 0) {
            revert ControllerDoesNotExist();
        }
        if (ControllersStorage.layout().weights[_controllerNew] != 0) {
            revert ControllerAlreadyExists();
        }
        // Add new controller before removing old to avoid threshold issues during replacing.
        _addController(_controllerNew, ControllersStorage.layout().weights[_controllerOld]);
        _removeController(_controllerOld);
    }

    /**
     * @dev Update the threshold required to invoke functions on the contract.
     * @param _threshold The new threshold required to invoke functions on the wallet.
     * @param _nonce A nonce to prevent replay attacks.
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function updateControlThreshold(
        uint256 _threshold,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_threshold, _nonce, _deadline, block.chainid)), _deadline, _signatures
        );
        _updateThreshold(_threshold);
    }

    /**
     * @dev Update the weight of a controller.
     * @param _controller The address of the controller to update the weight of.
     * @param _weight The new weight of the controller.
     * @param _nonce A nonce to prevent replay attacks.
     * @param _signatures Signatures from controllers to meet the threshold required to invoke functions on the wallet.
     */
    function updateControllerWeight(
        address _controller,
        uint256 _weight,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external {
        _requireMeetsControllersThreshold(
            keccak256(abi.encode(_controller, _weight, _nonce, _deadline, block.chainid)), _deadline, _signatures
        );
        ControllersStorage.layout().totalWeights =
            ControllersStorage.layout().totalWeights - ControllersStorage.layout().weights[_controller] + _weight;
        if (
            ControllersStorage.layout().totalWeights == 0
                || ControllersStorage.layout().totalWeights < ControllersStorage.layout().threshold
        ) {
            revert ThresholdImpossible();
        }
        ControllersStorage.layout().weights[_controller] = _weight;
    }

    /**
     * @dev Returns the threshold required to invoke functions on the contract.
     */
    function controlThreshold() external view returns (uint256) {
        return ControllersStorage.layout().threshold;
    }

    /**
     * @dev Returns the weight of a controller.
     * @param _controller Address of the controller to get the weight of.
     */
    function controllerWeight(address _controller) external view returns (uint256) {
        return ControllersStorage.layout().weights[_controller];
    }

    /**
     * @dev Returns the total weight of all controllers.
     */
    function controllersTotalWeight() external view returns (uint256) {
        return ControllersStorage.layout().totalWeights;
    }

    /**
     * @dev Check if the contract supports an interface.
     * @param interfaceId Interface ID of the function to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        if (interfaceId == type(IControllers).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _updateThreshold(uint256 _threshold) internal {
        ControllersStorage.layout().threshold = _threshold;
        if (
            ControllersStorage.layout().threshold == 0
                || ControllersStorage.layout().threshold > ControllersStorage.layout().totalWeights
        ) {
            revert InvalidThreshold();
        }
    }

    function _addController(address _controller, uint256 _weight) internal {
        ControllersStorage.layout().totalWeights += _weight;
        ControllersStorage.layout().weights[_controller] = _weight;
    }

    function _removeController(address _controller) internal {
        ControllersStorage.layout().totalWeights -= ControllersStorage.layout().weights[_controller];
        if (
            ControllersStorage.layout().totalWeights == 0
                || ControllersStorage.layout().totalWeights < ControllersStorage.layout().threshold
        ) {
            revert ThresholdImpossible();
        }
        ControllersStorage.layout().weights[_controller] = 0;
    }

    function _verifyControllersThresholdBySignatures(
        bytes32 _inputHash,
        bytes[] memory _signatures
    ) internal view returns (bool, string memory) {
        uint256 signerWeights = 0;

        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = Signatures.getSigner(_inputHash, _signatures[i]);

            if (ControllersStorage.layout().weights[signer] == 0) {
                return (false, "At least one signature not from a known controller");
            }

            bytes32 signatureHash = keccak256(_signatures[i]);

            if (ControllersStorage.layout().usedSignatures[signatureHash]) {
                return (false, "At least one signature already used");
            }

            signerWeights += ControllersStorage.layout().weights[signer];
        }

        if (signerWeights < ControllersStorage.layout().threshold) {
            return (false, "Signer weights does not meet threshold");
        }

        return (true, "");
    }

    function _requireMeetsControllersThresholdBytes(
        bytes memory _inputBytes,
        uint256 _deadline,
        bytes[] calldata _signatures
    ) internal {
        if (_deadline < block.timestamp) {
            revert DeadlineReached();
        }
        if (ControllersStorage.layout().threshold == 0) {
            revert ControllersNotInitialized();
        }
        (bool verified, string memory error) =
            _verifyControllersThresholdBySignatures(keccak256(_inputBytes), _signatures);
        require(verified, error);

        for (uint256 i = 0; i < _signatures.length; i++) {
            ControllersStorage.layout().usedSignatures[keccak256(_signatures[i])] = true;
        }
    }

    function _requireMeetsControllersThreshold(
        bytes32 _inputHash,
        uint256 _deadline,
        bytes[] calldata _signatures
    ) internal {
        if (_deadline < block.timestamp) {
            revert DeadlineReached();
        }
        if (ControllersStorage.layout().threshold == 0) {
            revert ControllersNotInitialized();
        }
        (bool verified, string memory error) = _verifyControllersThresholdBySignatures(_inputHash, _signatures);
        require(verified, error);

        for (uint256 i = 0; i < _signatures.length; i++) {
            ControllersStorage.layout().usedSignatures[keccak256(_signatures[i])] = true;
        }
    }
}
