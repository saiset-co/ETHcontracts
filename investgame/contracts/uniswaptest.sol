// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract UniSwap {
    constructor() {
        
    }


    //as IUniswapV3Factory
    function getPool(
        address addr1,
        address addr2,
        uint24 fee
    ) external view returns (address pool)
    {
        return address(this);
    }

    //as IUniswapV3Pool
    function slot0() external pure 
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return (1,0,0,0,0,0,true);
    }
    
    //as ISwapRouter
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) external payable returns (uint256 amountOut)
    {
        return params.amountIn;
    }


}