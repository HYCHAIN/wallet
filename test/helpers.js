const { ethers } = require('hardhat');
const {keccak256, solidityPack, getCreate2Address} = ethers.utils;

// See contracts/Wallet.sol 
const walletProxyBytecode = '0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3';

function calculateWalletCreate2Address(factoryAddress, salt, mainAddress) {
  const codePacked = solidityPack(['bytes', 'uint256'], [walletProxyBytecode, mainAddress]);
  const codeHashed = keccak256(codePacked);
  return getCreate2Address(factoryAddress, salt, codeHashed);
}

module.exports = {
  walletProxyBytecode,
  calculateWalletCreate2Address,
};