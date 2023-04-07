// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

interface IControllers {
  function addControllers(
    address[] calldata _controllers, 
    uint256[] calldata _weights,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function removeControllers(
    address[] calldata _controllers,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function updateControlThreshold(
    uint256 _threshold,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function updateControllerWeight(
    address _controller,
    uint256 _weight,
    uint256 _nonce,
    bytes[] calldata _signatures
  ) external;

  function controlThreshold() external view returns (uint256);
  function controllerWeight(address _controller) external view returns(uint256);
  function controllersTotalWeight() external view returns (uint256);
}