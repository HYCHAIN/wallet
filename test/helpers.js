const { ethers } = require('hardhat');
const { BigNumber } = ethers;
const {id, keccak256, defaultAbiCoder, solidityPack, getCreate2Address} = ethers.utils;

// See contracts/Wallet.sol 
const factoryProofMessage = id('Approve wallet creation');
const factoryDosSaltHash = id('DOS_SALT_HASH');
const walletProxyBytecode = '0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3';

function calculateDeployWithControllerSignedAddress(factoryAddress, mainAddress, signer) {
  const signature = generateFactoryProofSignature(signer);
  return _calculateWalletCreate2Address(factoryAddress, keccak256(signer.address), mainAddress);
}

function calculateDeployWithControllerUnsignedAddress(factoryAddress, mainAddress, salt) {
  const dosSalt = keccak256(defaultAbiCoder.encode([ 'bytes32', 'bytes32' ], [ salt, factoryDosSaltHash ]));
  return _calculateWalletCreate2Address(factoryAddress, dosSalt, mainAddress);
}

function _calculateWalletCreate2Address(factoryAddress, salt, mainAddress) {
  const codePacked = solidityPack(['bytes', 'uint256'], [walletProxyBytecode, mainAddress]);
  const codeHashed = keccak256(codePacked);
  return getCreate2Address(factoryAddress, salt, codeHashed);
}

function generateFactoryProofSignature(signer) {
  return signer.signMessage(factoryProofMessage);
}

module.exports = {
  calculateDeployWithControllerSignedAddress,
  calculateDeployWithControllerUnsignedAddress,
  generateFactoryProofSignature,
};