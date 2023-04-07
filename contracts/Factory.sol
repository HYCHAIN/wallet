// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Wallet.sol";
import "./modules/Main/IMain.sol";
import "./utils/Signatures.sol";

import "hardhat/console.sol";

contract Factory {
  bytes32 private constant PROOF_MESSAGE = keccak256("Approve wallet creation");
  bytes32 private constant DOS_XOR_HASH = keccak256("DOS_XOR_HASH");

  /**
   * @dev deployWithSignedController() is intended to allow us to support multichain smart
   * contract wallets with consistent addresses across chains. Using a signer/signature controller
   * approach with the salt prevents a DoS attack on other chain from signature reuse or controller
   * swaps for a given signature used on another chain.
   */

  function deployWithSignedController(address _main, bytes calldata _proofSignature) external returns (address _contract) {
    address signer = Signatures.getSigner(PROOF_MESSAGE, _proofSignature);
    bytes32 salt = keccak256(abi.encode(signer));
    return deploy(_main, signer, salt);
  }

  /**
   * @dev deployWithUnsignedController() is intended to allow the creation of a wallet controlled
   * by the provided controller. Created with an arbitrary salt. The provided salt is XOR'd with our
   * DOS_XOR_HASH constant to prevent DoS of multichain support for a given controller's wallets created
   * through deployWithSignedController().
   */

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