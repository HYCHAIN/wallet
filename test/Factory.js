const { expect } = require('chai');
const { ethers } = require("hardhat");
const helpers = require('./helpers');

describe('Factory.sol', () => {
  it('Should deploy main, factory and a wallet for _setup', async () => {
    await factoryContract.deployed();
    await mainContract.deployed();
    await walletContract.deployed();

    expect(await walletContract.supportsUpgrades()).to.equal(true); // see if contract returns true for simple call.
  });

  it('Should deploy a new Wallet through factory with an arbitrary controller', async () => {
    const salt = ethers.utils.id('randsalt');
    const walletAddress = helpers.calculateDeployWithUnsignedControllerAddress(factoryContract.address, mainContract.address, salt);
    await factoryContract.deployWithUnsignedController(mainContract.address, controller2.address, salt);
    const newWallet = await ethers.getContractAt("Wallet", walletAddress);

    expect(await walletContract.supportsUpgrades()).to.equal(true); // see if contract returns true for simple call.
  });

  it('Should deploy a new Wallet through factory with signer as controller', async () => {
    const walletAddress = helpers.calculateDeployWithSignedControllerAddress(factoryContract.address, mainContract.address, controller);
    const proofSignature = helpers.generateFactoryProofSignature(controller);
    await factoryContract.deployWithSignedController(mainContract.address, proofSignature);
    const newWallet = await ethers.getContractAt("Wallet", walletAddress);

    expect(await walletContract.supportsUpgrades()).to.equal(true); // see if contract returns true for simple call.
  });
});