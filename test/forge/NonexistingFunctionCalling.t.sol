// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { TestBase } from "./utils/TestBase.sol";

import { Calls, CallsStructs } from "contracts/modules/Calls/Calls.sol";

import "forge-std/console.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) { }
}

contract Counter {
    uint256 public count;

    function increment(uint256 _amount) public {
        count += _amount;
    }
}

contract NonexistingFunctionCallingTests is TestBase {
    ERC20Mock erc20;
    Counter _counter;

    function setUp() public {
        erc20 = new ERC20Mock("Testing", "TST");
        _counter = new Counter();
    }

    function testCallingNonERC20ContractReverts() public {
        vm.expectRevert();
        IERC20(address(_counter)).totalSupply();

        try IERC20(address(_counter)).totalSupply() returns (uint256) {
            fail("Expected revert got value instead");
        } catch { }
    }

    function testCallingNonERC20EOAReverts() public {
        // Cannot call the following directly because forge doesn't propagate the revert correctly.
        // If you use vm.expectRevert it 'doesn't revert', however if you remove it it reverts.
        // uint256 supp = IERC20(alice).totalSupply();

        vm.expectRevert();
        try IERC20(alice).totalSupply() returns (uint256) {
            fail("Expected revert got value instead");
        } catch { }
    }

    function testCallingNonERC20EOALowLevelSucceeds() public {
        (bool success,) = alice.call(abi.encodeWithSelector(IERC20.totalSupply.selector));
        assertTrue(success);
    }
}
