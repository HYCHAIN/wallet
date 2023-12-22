// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { TestBase } from "./utils/TestBase.sol";

import { ERC1271 } from "contracts/modules/ERC1271/ERC1271.sol";

import "forge-std/console.sol";

contract SCA is ERC1271 {
    function initialize(address _controller) public initializer {
        __Controllers_init(_controller);
    }
}

contract ERC1271Test is TestBase {
    bytes4 private constant ERC1271_MAGIC_BYTES_BYTES_SUCCESS = 0x20c13b0b;
    bytes4 private constant ERC1271_MAGIC_BYTES32_BYTES_SUCCESS = 0x1626ba7e;
    bytes4 private constant ERC1271_MAGIC_BYTES_FAILURE = 0x00000000;

    SCA _sca;

    uint256 _deadline = 9999999;

    function setUp() public {
        _sca = SCA(proxify(address(new SCA())));
        _sca.initialize(signingAuthority);
    }

    function testValidSignatureIsValid() public {
        bytes32 _hash = keccak256(abi.encode("I am a super cool message"));
        bytes memory _sig = signHashAsMessage(signingPK, _hash);

        assertEq(_sca.isValidSignature(_hash, _sig), ERC1271_MAGIC_BYTES32_BYTES_SUCCESS);
    }

    function testInvalidSignatureIsInvalid() public {
        bytes32 _hash = keccak256(abi.encode("I am a super cool message"));
        uint256 _signingPK2 = 2;
        bytes memory _sig = signHashAsMessage(_signingPK2, _hash);

        assertEq(_sca.isValidSignature(_hash, _sig), ERC1271_MAGIC_BYTES_FAILURE);
    }

    function testMultiControllerWeightReachedValidSignature() public {
        uint256 _weight = 1;
        uint256 _nonce = 1;
        uint256 _signingPK2 = 2;
        address _signingPK2Addr = vm.addr(_signingPK2);

        bytes memory _sig = signHashAsMessage(
            signingPK,
            keccak256(abi.encode(arraySingle(deployer), arraySingle(_weight), _nonce, _deadline, block.chainid))
        );

        // Add deployer as controller
        _sca.addControllers(arraySingle(deployer), arraySingle(_weight), _nonce, arraySingle(_sig), _deadline);

        // Add _signingPK2 as controller
        _sig = signHashAsMessage(
            signingPK,
            keccak256(abi.encode(arraySingle(_signingPK2Addr), arraySingle(_weight), _nonce, _deadline, block.chainid))
        );
        _sca.addControllers(arraySingle(_signingPK2Addr), arraySingle(_weight), _nonce, arraySingle(_sig), _deadline);

        // Total weight should be 3, so we want 2 signatures to pass
        uint256 _newThreshold = 2;
        _sig = signHashAsMessage(signingPK, keccak256(abi.encode(_newThreshold, _nonce, _deadline, block.chainid)));
        _sca.updateControlThreshold(_newThreshold, _nonce, arraySingle(_sig), _deadline);
        assertEq(_sca.controlThreshold(), _newThreshold);

        bytes32 _hash = keccak256(abi.encode("I am a super cool message"));

        _sig = signHashAsMessage(signingPK, _hash);

        assertEq(_sca.isValidSignature(_hash, _sig), ERC1271_MAGIC_BYTES_FAILURE);

        _sig = abi.encodePacked(_sig, signHashAsMessage(_signingPK2, _hash));

        assertEq(_sca.isValidSignature(_hash, _sig), ERC1271_MAGIC_BYTES32_BYTES_SUCCESS);
    }
}
