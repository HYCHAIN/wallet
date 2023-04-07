const { ethers } = require('hardhat');
const { BigNumber } = ethers;
const {id, keccak256, solidityPack, getCreate2Address} = ethers.utils;

// See contracts/Wallet.sol 
const factoryProofMessage = id('Approve wallet creation');
const factoryDosXorHash = id('DOS_XOR_HASH');
const walletProxyBytecode = '0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3';

function calculateDeployWithSignedControllerAddress(factoryAddress, mainAddress, signer) {
  const signature = generateFactoryProofSignature(signer);
  return _calculateWalletCreate2Address(factoryAddress, keccak256(signer.address), mainAddress);
}

function calculateDeployWithUnsignedControllerAddress(factoryAddress, mainAddress, salt) {
  const xorSalt = BigNumber.from(salt).xor(BigNumber.from(factoryDosXorHash)).toHexString();
  return _calculateWalletCreate2Address(factoryAddress, xorSalt, mainAddress);
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
  calculateDeployWithSignedControllerAddress,
  calculateDeployWithUnsignedControllerAddress,
  generateFactoryProofSignature,
};