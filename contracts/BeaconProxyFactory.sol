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

interface IBeaconProxyFactory {
    function beacon() external view returns (address);
}

contract FactoryCreatedBeaconProxy is BeaconProxy {
    constructor() BeaconProxy(IBeaconProxyFactory(msg.sender).beacon(), "") {}
}

contract BeaconProxyFactory is IBeaconProxyFactory {
    bytes32 public constant proxyHash = keccak256(type(FactoryCreatedBeaconProxy).creationCode);

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

    function getSalt(address user, bytes32 userSalt) public pure returns (bytes32) {
        return keccak256(abi.encode(user, userSalt));
    }

    // Any initializations (setting owner, initial state, etc) must be done immediately following the return
    //  of this call.
    function createProxy(bytes32 userSalt) external returns (address createdContract_) {
        bytes32 salt = getSalt(msg.sender, userSalt);
        createdContract_ = address(new FactoryCreatedBeaconProxy{ salt: salt }());
        // If the beacon proxy fails to deploy, it will return address(0)
        if(createdContract_ == address(0)) {
            revert BeaconProxyDeployFailed();
        }
    }

    function calculateExpectedAddress(bytes32 salt)
        public
        view
        returns (address expectedAddress_)
    {
        expectedAddress_ = Create2.computeAddress(salt, proxyHash, address(this));
    }

    function calculateExpectedAddress(address user, bytes32 userSalt)
        public
        view
        returns (address expectedAddress_)
    {
        expectedAddress_ = calculateExpectedAddress(getSalt(user, userSalt));
    }
}
