try {
  require("@nomicfoundation/hardhat-toolbox");
} catch (error) {
  console.warn('hardhat-toolbox is not installed. It is only needed for contract tests.');
}

module.exports = {
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
  defaultNetwork: 'hardhat',
  networks: {
    homestead: {
      url: '',
    },
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    pretty: true,
  },
  etherscan: {
    apiKey: 'VUV9MN1SBXZH9WXBR9PU49H53KZ56KWDYS',
  },
  mocha: {
    timeout: 60 * 60 * 1000,
  },
};