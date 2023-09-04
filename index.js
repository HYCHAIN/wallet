/*
 * Allows importation of the package & direct usage of compiled bytecode
 * from generated artifacts of postinstall `npx hardhat compile`.
 */

const fs = require('fs');
const path = require('path');

const contracts = {};

const recurseContracts = rootDirectory => {
  const directoryItems = fs.readdirSync(rootDirectory);

  for (let i = 0; i < directoryItems.length; i++) {
    const directoryItem = directoryItems[i];
    const itemPath = `${rootDirectory}/${directoryItem}`;

    if (fs.lstatSync(itemPath).isDirectory()) {
      recurseContracts(itemPath);
    }

    if (directoryItem.includes('.json') && !directoryItem.includes('.dbg.json')) {
      const contractName = directoryItem.replace('.json', '');

      contracts[contractName] = require(itemPath);
    }
  }
}

recurseContracts(path.join(__dirname, './artifacts/contracts'));
recurseContracts(path.join(__dirname, './artifacts/@openzeppelin'));

// add precompiled contracts
contracts.CREATE3Factory = require('./precompiled/CREATE3Factory.json');

module.exports = contracts;
