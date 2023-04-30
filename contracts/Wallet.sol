// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

/**
 * PROXY
 *     ---------------------------
 *     CODE  OP              STACK
 *     ---------------------------
 *     0x36  CALLDATASIZE    cds
 *     0x3d  RETURNDATASIZE  0 cds
 *     0x3d  RETURNDATASIZE  0 0 cds
 *     0x37  CALLDATACOPY
 *     0x3d  RETURNDATASIZE  0
 *     0x3d  RETURNDATASIZE  0 0
 *     0x3d  RETURNDATASIZE  0 0 0
 *     0x36  CALLDATASIZE    cds 0 0 0
 *     0x3d  RETURNDATASIZE  0 cds 0 0 0
 *     0x30  ADDRESS         addr 0 cds 0 0 0
 *     0x54  SLOAD           mainAddr 0 cds 0 0 0 // load mainAddr target from addr slot
 *     0x5a  GAS             gas mainAddr 0 cds 0 0 0
 *     0xf4  DELEGATECALL    success 0
 *     0x3d  RETURNDATASIZE  rds success 0
 *     0x82  DUP3            0 rds success 0
 *     0x80  DUP1            0 0 rds success 0
 *     0x3e  RETURNDATACOPY  success 0
 *     0x90  SWAP1           0 success
 *     0x3d  RETURNDATASIZE  rds 0 success
 *     0x91  SWAP2           success 0 rds
 *     0x60  PUSH1:0x18      0x18 success 0 rds
 *     0x57  JUMPI           0 rds
 *     0xfd  REVERT
 *     0x5b  JUMPDEST        0 rds
 *     0xf3  RETURN
 *     flattened: 0x363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3
 *
 *     DEPLOYER
 *     ---------------------------
 *     CODE  OP              STACK
 *     ---------------------------
 *     0x60  PUSH1:0x3a      0x3a
 *     0x60  PUSH1:0x0e      0x0e 0x3a
 *     0x3d  RETURNDATASIZE  0 0x0e 0x3a
 *     0x39  CODECOPY
 *     0x60  PUSH1:0x1a      0x1a
 *     0x80  DUP1            0x1a 0x1a
 *     0x51  MLOAD           mainAddr 0x1a
 *     0x30  ADDRESS         addr mainAddr 0x1a // set mainAddr target on addr slot
 *     0x55  SSTORE          0x1a
 *     0x3d  RETURNDATASIZE  0 0x1a
 *     0xf3  RETURN
 *     flattened: 0x603a600e3d39601a805130553df3
 *
 *     complete: 0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3
 */

library Wallet {
    bytes internal constant code = hex"603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3";
}
