// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UDSTest is ERC20
{
    constructor() ERC20("UDS token", "UDS") 
    {
    }
    function Mint(uint256 amount) external
    {
         _mint(msg.sender, amount);
    }
}

contract UGOLDTest is ERC20
{
    constructor() ERC20("UGOLD token", "UGOLD") 
    {
    }
    function Mint(uint256 amount) external
    {
         _mint(msg.sender, amount);
    }
}

contract USDTest is ERC20
{
    constructor() ERC20("USDTest token", "USDT") 
    {
    }
    function Mint(uint256 amount) external
    {
         _mint(msg.sender, amount);
    }
}
