// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// example script cli:
//   forge script script/Troubleshooting.s.sol -f mumbai

/**
 * @dev Used for running forks against the network to troubleshoot issues if needed 
 */
contract TroubleshootingScript is Script {

    function run() external {
        console.log("RUNNING TROUBLESHOOTING SCRIPT");
        vm.selectFork(vm.createFork("RPC_URL"));
        // ... prank as adresses and run transactions here
    }
}
