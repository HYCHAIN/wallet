const { expect } = require('chai');

describe('Factory.sol', () => {
  it('Should deploy main, factory and a wallet', async () => {
    await factoryContract.deployed();
    await mainContract.deployed();
    await walletContract.deployed();

    // see if contract returns true for simple call.
    expect(await walletContract.supportsUpgrades()).to.equal(true);
  });
});