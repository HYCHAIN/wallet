// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//
pragma solidity 0.8.18;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IMain } from "./modules/Main/IMain.sol";
import { Signatures } from "./utils/Signatures.sol";

interface IBeaconProxyFactory {
    function beacon() external view returns (address);
}

contract FactoryCreatedBeaconProxy is BeaconProxy {
    constructor() BeaconProxy(IBeaconProxyFactory(msg.sender).beacon(), "") {}
}

contract BeaconProxyFactory is IBeaconProxyFactory {
    bytes32 public constant proxyHash = keccak256(type(FactoryCreatedBeaconProxy).creationCode);
    bytes32 private constant PROOF_MESSAGE = keccak256("Approve HYTOPIA wallet creation");

    event ContractDeployed(address indexed contractAddress, bool indexed wasSigned);

    error BeaconProxyDeployFailed();
    error BeaconImplInvalid();

    /**
     * @dev Having this reference allows BeaconProxy contracts to be created without requiring the
     *   UpgradeableBeacon address constructor argument, since we can assume that the factory is creating
     *    every BeaconProxy that needs to be linked.
     */
    address public override beacon;

    constructor(address _beaconImpl) {
        if(_beaconImpl == address(0)) {
            revert BeaconImplInvalid();
        }

        beacon = address(new UpgradeableBeacon(_beaconImpl));
        // Transfer ownership to the factory deployer, otherwise the factory will own the beacon.
        UpgradeableBeacon(beacon).transferOwnership(msg.sender);
    }

    /**
     * @dev Deploys a new BeaconProxy contract based on the salt provided and the caller of the contract.
     * @param _userSalt The salt to use for the deterministic address calculation. Gets concatenated with the caller address.
     */
    function createProxy(bytes32 _userSalt) external returns (address createdContract_) {
        createdContract_ = _create(getSalt(msg.sender, _userSalt));

        emit ContractDeployed(createdContract_, false);
    }

    /**
     * @dev Deploys a new BeaconProxy contract and passes in the signer to the initializer function.
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
     * @dev Calculates the expected address of a BeaconProxy contract based on the salt provided without combining an address.
     */
    function calculateExpectedAddress(bytes32 _salt)
        public
        view
        returns (address expectedAddress_)
    {
        expectedAddress_ = Create2.computeAddress(_salt, proxyHash, address(this));
    }

    /**
     * @dev Calculates the expected address of a BeaconProxy contract based on the salt provided and a given address.
     */
    function calculateExpectedAddress(address _user, bytes32 _userSalt)
        public
        view
        returns (address expectedAddress_)
    {
        expectedAddress_ = calculateExpectedAddress(getSalt(_user, _userSalt));
    }

    /**
     * @dev Deploys a new BeaconProxy contract based on the salt provided and the caller of the contract.
     * @param _salt The salt to use for the deterministic address calculation.
     */
    function _create(bytes32 _salt) internal returns (address createdContract_) {
        createdContract_ = address(new FactoryCreatedBeaconProxy{ salt: _salt }());
        // If the beacon proxy fails to deploy, it will return address(0)
        if(createdContract_ == address(0)) {
            revert BeaconProxyDeployFailed();
        }
    }
}
