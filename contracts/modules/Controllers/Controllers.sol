// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IControllers.sol";
import "../../utils/Signatures.sol";
import "./ControllersStorage.sol";

contract Controllers is IControllers, ERC165 {
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

  function _addController(address _controller, uint256 _weight) internal {
    ControllersStorage.layout().totalWeights += _weight;
    ControllersStorage.layout().weights[_controller] = _weight;    
  }

  function removeControllers(
    address[] calldata _controllers,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_controllers, _nonce, block.chainid)), _signatures)
  {
    for (uint256 i = 0; i < _controllers.length; i++) {
      _removeController(_controllers[i]);
    }
  }

  function _removeController(address _controller) internal {
    ControllersStorage.layout().totalWeights -= ControllersStorage.layout().weights[_controller];
    require(ControllersStorage.layout().totalWeights > 0 && ControllersStorage.layout().totalWeights >= ControllersStorage.layout().threshold, "Threshold would be impossible");
    ControllersStorage.layout().weights[_controller] = 0;
  }

  function updateControlThreshold(
    uint256 _threshold,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_threshold, _nonce, block.chainid)), _signatures)
  {
    require(ControllersStorage.layout().threshold > 0 && ControllersStorage.layout().threshold <= ControllersStorage.layout().totalWeights, "Invalid threshold");
    ControllersStorage.layout().threshold = _threshold;
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
    ControllersStorage.layout().totalWeights = ControllersStorage.layout().totalWeights - ControllersStorage.layout().weights[_controller] + _weight;
    require(ControllersStorage.layout().totalWeights > 0 && ControllersStorage.layout().totalWeights >= ControllersStorage.layout().threshold, "Threshold would be impossible");
    ControllersStorage.layout().weights[_controller] = _weight;
  }

  function controlThreshold() external view returns (uint256) {
    return ControllersStorage.layout().threshold;
  }

  function controllerWeight(address _controller) external view returns(uint256) {
    return ControllersStorage.layout().weights[_controller];
  }

  function controllersTotalWeight() external view returns (uint256) {
    return ControllersStorage.layout().totalWeights;
  }

  function verifyControllersThresholdBySignatures(
    bytes32 _inputHash, 
    bytes[] memory _signatures
  ) 
    internal 
    view 
    returns (bool, string memory) 
  {
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
    (bool verified, string memory error) = verifyControllersThresholdBySignatures(_inputHash, _signatures);
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

