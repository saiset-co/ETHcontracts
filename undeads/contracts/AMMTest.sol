
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AMMTest
{
    using SafeERC20 for IERC20;


    constructor()
    {

    }
    function getAmountsOut(uint amountIn, address[] memory path)  pure  external  returns (uint[] memory amounts)
    {
        amounts=new uint[](1);
        amounts[0]=amountIn;
        amounts[1]=amountIn;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts)
    {

        //1:1
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[1]).safeTransfer(to, amountIn);


        amounts=new uint[](1);
        amounts[0]=amountIn;
    }


}

   