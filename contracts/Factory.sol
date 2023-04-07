// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity 0.8.18;

import "./Wallet.sol";
import "./modules/Main/IMain.sol";
import "./utils/Signatures.sol";

import "hardhat/console.sol";

contract Factory {
  bytes32 private constant PROOF_MESSAGE = keccak256("Approve wallet creation");
  bytes32 private constant DOS_SALT_HASH = keccak256("DOS_SALT_HASH");

  /**
   * @dev deployWithControllerSigned() is intended to allow us to support multichain smart
   * contract wallets with guarenteed consistent addresses across chains. Using a signer/signature controller
   * approach with the salt prevents a DoS attack on other chains from signature reuse or controller
   * swaps for a given signature/salt.
   */

  function deployWithControllerSigned(address _main, bytes calldata _proofSignature) external returns (address) {
    address signer = Signatures.getSigner(PROOF_MESSAGE, _proofSignature);
    bytes32 salt = keccak256(abi.encode(signer));
    return deploy(_main, signer, salt);
  }

  /**
   * @dev deployWithControllerUnsigned() is intended to allow the creation of a wallet controlled
   * by the provided controller. Any controller can be provided. Created with an arbitrary salt. The 
   * provided salt is hashed with our DOS_SALT_HASH constant to prevent DoS of multichain support for a given 
   * controller's wallets created through deployWithControllerSigned().
   */

  function deployWithControllerUnsigned(address _main, address _controller, bytes32 _salt) external payable returns (address) {
    bytes32 salt = keccak256(abi.encode(_salt, DOS_SALT_HASH));
    return deploy(_main, _controller, salt);
  }

  function deploy(address _main, address _controller, bytes32 _salt) private returns (address _wallet) {
    bytes memory code = abi.encodePacked(Wallet.code, uint256(uint160(_main)));
    assembly { _wallet := create2(callvalue(), add(code, 32), mload(code), _salt) }
    require(_wallet != address(0), "Wallet already created for provided salt or signature.");
    IMain(_wallet).initialize(_controller);
  }
}