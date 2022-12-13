
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract AMMTest
{
    constructor()
    {

    }
    function getAmountsOut(uint amountIn, address[] memory path)  pure  external  returns (uint[] memory amounts)
    {
        amounts=new uint[](1);
        amounts[0]=amountIn;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external pure returns (uint[] memory amounts)
    {
        amounts=new uint[](1);
        amounts[0]=amountIn;
    }

}

   