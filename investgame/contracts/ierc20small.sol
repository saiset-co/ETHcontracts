// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20Small {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
