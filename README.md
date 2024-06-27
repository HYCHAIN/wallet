# HYCHAIN Smart Contract Wallet

The HYCHAIN Smart Contract Wallet is a sophisticated and secure solution for managing user accounts on the blockchain. It leverages a multi-signer authority model, gasless transactions, and a unique Session authorization implementation. The wallet conforms to several standards including EIP-1271 for smart contract signatures, EIP-4337 for account abstraction, and EIP-1967 for beacon proxies. This allows HYCHAIN to create, transact, and manage users' accounts without holding total custody over their assets.

## Initialization, Building and Testing

To initialize the repository, build the contracts, and run the forge tests, follow the steps below:

### Initializing the Repository

1. Clone the repository: `git clone https://github.com/hychain/wallet`
2. Navigate into the cloned repository: `cd wallet`
3. Install the necessary dependencies: `npm install`

### Building the Contracts

1. Build the contracts: `forge build`

### Running the Forge Tests

1. Run the tests: `forge test`

### Scripts

The deployment of the HYCHAIN Smart Contract Wallet involves executing several scripts in a specific order. Below is a brief explanation of each script and its role in the deployment process.

#### DeployCreate3Factory.s.sol

This script deploys a new CREATE3Factory contract. The CREATE3Factory contract is a factory contract that deploys a minimal proxy to deploy new contrcts using the CREATE2 opcode. This allows for deterministic deployment of contracts regardless of contract bytecode, meaning the address of the contract can be known before it is deployed even if it is modified.

After deploying, save the address to the `script/ScriptUtils.sol` file as `_createFactory = CREATE3Factory({DEPLOYED_ADDRESS_HERE})`

An example command to execute the script is as follows:
```
forge script script/deploy/create3/DeployCreate3Factory.s.sol --fork-url http://localhost:8545 --broadcast
```

#### DeployFactory.s.sol

This script deploys a new HYCHAIN Wallet Factory contract using the CREATE3Factory previously deployed. The HYCHAIN Wallet Factory contract is responsible for deploying new instances of the HYCHAIN Smart Contract Wallet. It uses the uups proxy pattern, which allows the logic of the wallet to be upgraded on a wallet-by-wallet basis.

NOTE: Select a desired `_factorySalt` value for determining what address you want when deploying.

After deploying, save the address to the `script/ScriptUtils.sol` file as `_factoryAddress = {DEPLOYED_ADDRESS_HERE}`

An example command to execute the script is as follows:
```
forge script script/deploy/DeployFactory.s.sol --rpc-url http://localhost:8545 --broadcast --verify
```

## Upgrading the Factory's Wallet Implementation

Since the Factory is non-upgradeable, we must redeploy every new version of the wallet implementation.

After modifying the wallet implementation, change the factory salt in `ScriptUtils.sol` and re-run the above DeployFactory.s.sol script which will deploy a new factory with a new Main implementation.

## Upgrading a Wallet's Implementation
To upgrade an existing wallet's implementation, the owner of the wallet must simply call the `upgradeToAndCall()`
function which requires consensus from the controllers before upgrading via the UUPS Proxy standard.

## Contract Modules

Each of the following contracts play a crucial role in the functionality of the HYCHAIN Smart Contract Wallet, providing a secure and flexible solution for managing user accounts on the blockchain.

### Controllers.sol

The `Controllers.sol` contract is responsible for managing the controllers of the wallet. Controllers are entities that have the authority to perform certain actions on behalf of the wallet. The contract provides functions to add and remove controllers, update their weights, and check if a set of signatures meets the required threshold for a certain action.

Controller thresholds depicts the relative weight that is required to be able to invoke a transaction for the account. For instance, a sole-controller would have 1 controller with a given weight (i.e 1) that equals the controller threshold (i.e also 1). A simple example of a recommended solution would be a 2/3 majority threshold of 3 controllers with 1 weight each and a 2 controller threshold. This allows for a user to have a hot+cold auth, plus a dApp auth for optimal UX and security.

### SessionCalls.sol

The `SessionCalls.sol` contract is responsible for managing sessions. A session is a period during which a user can perform certain actions without needing to provide a signature for each action. The contract provides functions to start and end sessions, and to perform calls within a session.

Sessions track all asset interactions and ensures session owners can only interact with the preauthorized asset(s), and utilizes the `Controllers` implementation for all calls to starting/stopping a session.

### Calls.sol

The `Calls.sol` contract provides the basic functionality for making calls to other contracts. It provides functions to make a single call or multiple calls in one transaction, and utilizes the `Controllers` implementation for all calls.

#### BeaconProxyFactory.sol

The `BeaconProxyFactory.sol` contract is used to create new instances of the HYCHAIN Smart Contract Wallet. It uses the beacon proxy pattern, which allows the logic of the wallet to be upgraded without needing to deploy new instances.

### Authors

- [T1Dev](https://twitter.com/pr0zy)
- [ArkDev](https://twitter.com/iamarkdev)
