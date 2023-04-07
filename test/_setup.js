const { ethers } = require('hardhat');
const { calculateDeployWithControllerUnsignedAddress } = require('./helpers.js');
const { HashZero } = ethers.constants;

global.factoryContract;
global.mainContract;
global.walletContract;
global.deployer;
global.controller;
global.controller2;

beforeEach(async () => {
  const [ _deployer, _controller, _controller2, ..._otherAddresses ] = await ethers.getSigners();

  const Main = await ethers.getContractFactory('Main');
  const Factory = await ethers.getContractFactory('Factory');

  deployer = _deployer;
  controller = _controller;
  controller2 = _controller2;

  factoryContract = await Factory.deploy();
  mainContract = await Main.deploy();

  const salt = HashZero;
  const computedWalletAddress = calculateDeployWithControllerUnsignedAddress(factoryContract.address, mainContract.address, salt);
  const createWalletTx = await factoryContract.deployWithControllerUnsigned(mainContract.address, controller.address, salt);

  walletContract = Main.attach(computedWalletAddress);
});