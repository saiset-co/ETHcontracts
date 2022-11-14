// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract TestCoin is ERC20
{
    constructor() ERC20("USDTest token", "USDT") 
    {
    }
    function Mint(uint256 amount) external
    {
         _mint(msg.sender, amount);
    }
    function MintTo(address to, uint256 amount) external
    {
         _mint(to, amount);
    }

    function deposit() public payable {
    }


    function Test() external
    {
         console.log("msg.sender=%s",msg.sender);
    }
    function Sender() public view returns(address)
    {
          return msg.sender;
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
    function MintTo(address to, uint256 amount) external
    {
         _mint(to, amount);
    }

    function deposit(address user, bytes calldata depositData)
        external
    {
        //uint256 amount = abi.decode(depositData, (uint256));
    }
}
