try {
    require("@nomicfoundation/hardhat-toolbox");
} catch (error) {
    console.warn('hardhat-toolbox is not installed. It is only needed for contract tests.');
}
try {
    require("@nomicfoundation/hardhat-foundry");
} catch (error) {
    console.warn(
        'hardhat-foundry is not installed. It is needed for compiling contracts that use Foundry '
        + '(like tests or scripts).');
}

module.exports = {
    solidity: {
        version: '0.8.23',
        settings: {
            optimizer: {
                enabled: true,
                runs: 100,
            },
            evmVersion: "paris"
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
