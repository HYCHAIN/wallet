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

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IMain } from "contracts/interfaces/IMain.sol";
import { Signatures } from "./utils/Signatures.sol";

interface IWalletProxyFactory {
    function latestWalletImplementation() external view returns (address);
}

contract FactoryCreatedUUPSProxy is ERC1967Proxy {
    constructor() ERC1967Proxy(IWalletProxyFactory(msg.sender).latestWalletImplementation(), "") { }
}

contract WalletProxyFactory {
    bytes32 public constant proxyHash = keccak256(type(FactoryCreatedUUPSProxy).creationCode);
    bytes32 private constant PROOF_MESSAGE = keccak256("Approve HYTOPIA wallet creation");

    event ContractDeployed(address indexed contractAddress, bool indexed wasSigned);

    error WalletProxyDeployFailed();
    error WalletImplInvalid();

    /**
     * @dev Having this reference allows WalletProxy contracts to be created without requiring the
     *   implementation contract address constructor argument, which makes it easier to calculate the proxy wallet address
     */
    address public latestWalletImplementation;

    constructor(address _walletImpl) {
        if (_walletImpl == address(0)) {
            revert WalletImplInvalid();
        }

        latestWalletImplementation = _walletImpl;
    }

    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _userSalt The salt to use for the deterministic address calculation. Gets concatenated with the caller address.
     */
    function createProxy(bytes32 _userSalt) external returns (address createdContract_) {
        createdContract_ = _create(getSalt(msg.sender, _userSalt));

        emit ContractDeployed(createdContract_, false);
    }

    /**
     * @dev Deploys a new WalletProxy contract and passes in the signer to the initializer function.
     *  It is assumed that ownership is transferred to the signer in the initializer, otherwise this operation can be front-run.
     * @param _proofSignature The signature of the address that will be initialized for the proxy.
     */
    function createProxyFromSignature(bytes calldata _proofSignature) external returns (address createdContract_) {
        address _signer = Signatures.getSigner(PROOF_MESSAGE, _proofSignature);
        bytes32 _salt = keccak256(abi.encode(_signer));
        createdContract_ = _create(_salt);

        IMain(createdContract_).initialize(_signer);

        emit ContractDeployed(createdContract_, true);
    }

    /**
     * @dev Returns an address-combined salt for the deterministic address calculation.
     */
    function getSalt(address _user, bytes32 _userSalt) public pure returns (bytes32) {
        return keccak256(abi.encode(_user, _userSalt));
    }

    /**
     * @dev Calculates the expected address of a WalletProxy contract based on the salt provided without combining an address.
     */
    function calculateExpectedAddress(bytes32 _salt) public view returns (address expectedAddress_) {
        expectedAddress_ = Create2.computeAddress(_salt, proxyHash, address(this));
    }

    /**
     * @dev Calculates the expected address of a WalletProxy contract based on the salt provided and a given address.
     */
    function calculateExpectedAddress(
        address _user,
        bytes32 _userSalt
    ) public view returns (address expectedAddress_) {
        expectedAddress_ = calculateExpectedAddress(getSalt(_user, _userSalt));
    }

    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _salt The salt to use for the deterministic address calculation.
     */
    function _create(bytes32 _salt) internal returns (address createdContract_) {
        createdContract_ = address(new FactoryCreatedUUPSProxy{ salt: _salt }());
        // If the latestWalletImplementation proxy fails to deploy, it will return address(0)
        if (createdContract_ == address(0)) {
            revert WalletProxyDeployFailed();
        }
    }
}
