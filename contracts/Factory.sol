// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Wallet.sol";
import "./modules/Main/IMain.sol";
import "./utils/Signatures.sol";

contract Factory {
  bytes32 private constant PROOF_MESSAGE = keccak256("com.trymetafab");

  function deployWithSignedController(address _main, bytes calldata _proofSignature) external returns (address _contract) {
    address signer = Signatures.getSigner(PROOF_MESSAGE, _proofSignature);
    bytes32 salt = keccak256(abi.encode(signer));
    bytes memory code = abi.encodePacked(Wallet.code, uint256(uint160(_main)));
    assembly { _contract := create2(callvalue(), add(code, 32), mload(code), salt) }
    IMain(_contract).initialize(signer);
  }

  function deployWithController(address _main, address _controller, bytes32 _salt) external payable returns (address _contract) {
    bytes memory code = abi.encodePacked(Wallet.code, uint256(uint160(_main)));
    assembly { _contract := create2(callvalue(), add(code, 32), mload(code), _salt) }
    IMain(_contract).initialize(_controller);
  }
}