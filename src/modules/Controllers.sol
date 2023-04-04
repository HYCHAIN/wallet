// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "../utils/Signatures.sol";

abstract contract Controllers is Signatures {
  uint256 private threshold = 1;
  uint256 private totalWeights = 1;
  mapping(address => uint256) private weights;
  mapping(bytes32 => bool) private usedSignatures; // signature hash => bool

  constructor(address _controller) {
    weights[_controller] = 1;
  }

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
      address _controller = _controllers[i];
      uint256 _weight = _weights[i];
      totalWeights += _weight;
      weights[_controller] = _weight;
    }
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
      address _controller = _controllers[i];
      totalWeights -= weights[_controller];
      require(totalWeights > 0 && totalWeights >= threshold, "Threshold would be impossible");
      weights[_controller] = 0;
    }
  }

  function updateControlThreshold(
    uint256 _threshold,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_threshold, _nonce, block.chainid)), _signatures)
  {
    require(threshold > 0 && threshold <= totalWeights, "Invalid threshold");
    threshold = _threshold;
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
    totalWeights = totalWeights - weights[_controller] + _weight;
    require(totalWeights > 0 && totalWeights >= threshold, "Threshold would be impossible");
    weights[_controller] = _weight;
  }

  function controlThreshold() external view returns (uint256) {
    return threshold;
  }

  function controllerWeight(address _controller) external view returns(uint256) {
    return weights[_controller];
  }

  function controllersTotalWeight() external view returns (uint256) {
    return totalWeights;
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
      address signer = getSigner(_inputHash, _signatures[i]);

      if (weights[signer] == 0) {
        return (false, "At least one signature not from a known controller");
      }
      
      bytes32 signatureHash = keccak256(_signatures[i]);

      if (usedSignatures[signatureHash]) {
        return (false, "At least one signature already used");
      }

      signerWeights += weights[signer];
    }

    if (signerWeights < threshold) {
      return (false, "Signer weights does not meet threshold");
    }

    return (true, "");
  }

  modifier meetsControllersThreshold(bytes32 _inputHash, bytes[] calldata _signatures) {
    (bool verified, string memory error) = verifyControllersThresholdBySignatures(_inputHash, _signatures);
    require(verified, error);
    
    for (uint256 i = 0; i < _signatures.length; i++) {
      usedSignatures[keccak256(_signatures[i])] = true;
    }

    _;
  }
}

