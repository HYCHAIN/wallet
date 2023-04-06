const { ethers } = require('hardhat');
const { calculateWalletCreate2Address } = require('./helpers.js');
const { HashZero } = ethers.constants;

global.factoryContract;
global.mainContract;
global.walletContract;
global.deployer;
global.controller;

beforeEach(async () => {
  const [ _deployer, _controller, ..._otherAddresses ] = await ethers.getSigners();

  const Main = await ethers.getContractFactory('Main');
  const Factory = await ethers.getContractFactory('Factory');

  deployer = _deployer;
  controller = _controller;

  factoryContract = await Factory.deploy();
  mainContract = await Main.deploy();

  const computedWalletAddress = calculateWalletCreate2Address(factoryContract.address, HashZero, mainContract.address);
  const createWalletTx = await factoryContract.deployWithController(mainContract.address, controller.address, HashZero);

  walletContract = Main.attach(computedWalletAddress);
});