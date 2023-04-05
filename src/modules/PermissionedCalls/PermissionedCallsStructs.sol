// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

library PermissionedCallsStructs {
  struct ExecuteRequestPermitted {
    address executor;
    address target;
    uint256 value;
    bytes data;
  }

  struct ExecuteRequestPermission {
    uint64 unlockTimestamp;
    uint64 lastExecuteTimestamp;
    uint32 minExecuteInterval;
    uint32 executeCount;
    uint32 maxExecutes;
  }
}