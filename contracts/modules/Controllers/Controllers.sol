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
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IControllers } from "contracts/interfaces/IControllers.sol";
import { Signatures } from "../../utils/Signatures.sol";
import { ControllersStorage } from "./ControllersStorage.sol";

abstract contract Controllers is Initializable, IControllers, ERC165 {
    error InvalidThreshold();
    error ThresholdImpossible();
    error ControllersNotInitialized();

    constructor() {
        _disableInitializers();
    }

    function __Controllers_init(address _controller) internal onlyInitializing {
        _addController(_controller, 1);
        ControllersStorage.layout().threshold = 1;
    }

    /**
     * External Functions
     */

    function addControllers(
        address[] calldata _controllers,
        uint256[] calldata _weights,
        uint256 _nonce,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(keccak256(abi.encode(_controllers, _weights, _nonce, block.chainid)), _signatures)
    {
        for (uint256 i = 0; i < _controllers.length; i++) {
            _addController(_controllers[i], _weights[i]);
        }
    }

    function removeControllers(
        address[] calldata _controllers,
        uint256 _nonce,
        bytes[] calldata _signatures
    ) external meetsControllersThreshold(keccak256(abi.encode(_controllers, _nonce, block.chainid)), _signatures) {
        for (uint256 i = 0; i < _controllers.length; i++) {
            _removeController(_controllers[i]);
        }
    }

    function updateControlThreshold(
        uint256 _threshold,
        uint256 _nonce,
        bytes[] calldata _signatures
    ) external meetsControllersThreshold(keccak256(abi.encode(_threshold, _nonce, block.chainid)), _signatures) {
        ControllersStorage.layout().threshold = _threshold;
        if (
            ControllersStorage.layout().threshold == 0
                || ControllersStorage.layout().threshold > ControllersStorage.layout().totalWeights
        ) {
            revert InvalidThreshold();
        }
    }

    function updateControllerWeight(
        address _controller,
        uint256 _weight,
        uint256 _nonce,
        bytes[] calldata _signatures
    )
        external
        meetsControllersThreshold(keccak256(abi.encode(_controller, _weight, _nonce, block.chainid)), _signatures)
    {
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

    function controlThreshold() external view returns (uint256) {
        return ControllersStorage.layout().threshold;
    }

    function controllerWeight(address _controller) external view returns (uint256) {
        return ControllersStorage.layout().weights[_controller];
    }

    function controllersTotalWeight() external view returns (uint256) {
        return ControllersStorage.layout().totalWeights;
    }

    /**
     * Internal Functions
     */

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

    modifier meetsControllersThreshold(bytes32 _inputHash, bytes[] calldata _signatures) {
        if (ControllersStorage.layout().threshold == 0) {
            revert ControllersNotInitialized();
        }
        (bool verified, string memory error) = _verifyControllersThresholdBySignatures(_inputHash, _signatures);
        require(verified, error);

        for (uint256 i = 0; i < _signatures.length; i++) {
            ControllersStorage.layout().usedSignatures[keccak256(_signatures[i])] = true;
        }

        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        if (interfaceId == type(IControllers).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
