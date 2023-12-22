// SPDX-License-Identifier: Commons-Clause-1.0
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@ @@@@  @@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@@@@@@@ @@@@ @@@@@@@@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
// @@@@  @@@@    @@@@       @@@@    @@@@@@@@@@ @@@@       @@@@ @@@@  @@@@
//
// https://hytopia.com
//
pragma solidity 0.8.23;

interface IControllers {
    function addControllers(
        address[] calldata _controllers,
        uint256[] calldata _weights,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external;

    function removeControllers(
        address[] calldata _controllers,
        uint256 _newThreshold,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external;

    function replaceController(
        address _controllerOld,
        address _controllerNew,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external;

    function updateControlThreshold(
        uint256 _threshold,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external;

    function updateControllerWeight(
        address _controller,
        uint256 _weight,
        uint256 _nonce,
        bytes[] calldata _signatures,
        uint256 _deadline
    ) external;

    function controlThreshold() external view returns (uint256);
    function controllerWeight(address _controller) external view returns (uint256);
    function controllersTotalWeight() external view returns (uint256);
}
