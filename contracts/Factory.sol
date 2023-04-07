// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Wallet.sol";
import "./modules/Main/IMain.sol";
import "./utils/Signatures.sol";

import "hardhat/console.sol";

contract Factory {
  bytes32 private constant PROOF_MESSAGE = keccak256("Approve wallet creation");
  bytes32 private constant DOS_XOR_HASH = keccak256("DOS_XOR_HASH");

  function deployWithSignedController(address _main, bytes calldata _proofSignature) external returns (address _contract) {
    address signer = Signatures.getSigner(PROOF_MESSAGE, _proofSignature);
    bytes32 salt = keccak256(abi.encode(signer));
    return deploy(_main, signer, salt);
  }

  function deployWithUnsignedController(address _main, address _controller, bytes32 _salt) external payable returns (address) {
    bytes32 salt = _salt ^ DOS_XOR_HASH;
    return deploy(_main, _controller, salt);
  }

  function deploy(address _main, address _controller, bytes32 _salt) private returns (address _wallet) {
    bytes memory code = abi.encodePacked(Wallet.code, uint256(uint160(_main)));
    assembly { _wallet := create2(callvalue(), add(code, 32), mload(code), _salt) }
    require(_wallet != address(0), "Wallet already created for provided salt or signature.");
    IMain(_wallet).initialize(_controller);
  }
}