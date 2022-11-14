// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./Admin.sol";

//import "hardhat/console.sol";

contract InvestGame is Admin {
    mapping(address => uint256) private MapPrice;
    mapping(address => uint256) private MapTradeCoin;

    //       client             token      amount
    mapping(address => mapping(address => uint256)) private MapWallet;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private EnumTradeRequest;

    uint24 public constant poolFee = 3000; //set the pool fee to 0.3%.
    //ISwapRouter public immutable swapRouter;
    ISwapRouter public swapRouter;
    IUniswapV3Factory swapFactory;
    address addrETH;
    address addrUSDT;

    /*
    constructor(IUniswapV3Factory _factory, ISwapRouter _swapRouter) {
        swapFactory=_factory;
        swapRouter = _swapRouter;
    }
*/

    //see addr from https://docs.uniswap.org/protocol/reference/deployments
    //Polygon:
    //0x1F98431c8aD98523631AE4a59f267346ea31F984
    //0xE592427A0AEce92De3Edee1F18E0157C05861564
    //0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    //0xc2132d05d31c914a87c6611c10748aeb04b58e8f //mainnet

    function setUniswap(
        address _factory,
        address _swapRouter,
        address _addrETH,
        address _addrUSDT
    ) public onlyAdmin {
        swapFactory = IUniswapV3Factory(_factory);
        swapRouter = ISwapRouter(_swapRouter);
        addrETH = _addrETH;
        addrUSDT = _addrUSDT;
    }

    function setListingPrice(address addrCoin, uint256 price) public onlyAdmin {
        MapPrice[addrCoin] = price;
    }

    function setTradeToken(address addrToken, uint256 rank) public onlyAdmin {
        require(addrToken != address(0), "Error token smart address");
        require(rank > 0, "Error, rank is zero");

        TransferHelper.safeApprove(addrToken, address(swapRouter), 1e36);

        MapTradeCoin[addrToken] = rank;
    }

    function delTradeToken(address addrToken) external onlyAdmin {
        require(addrToken != address(0), "Error token smart address");
        delete MapTradeCoin[addrToken];
    }

    function requestTradeToken(address addrToken, address addrCoin)
        external
        payable
    {
        uint256 Price = MapPrice[addrCoin];
        require(Price > 0, "Error, listing Price is zero");
        require(addrToken != address(0), "Error token smart address");

        require(
            hasPool(addrToken, addrETH) || hasPool(addrToken, addrUSDT),
            "Need pool ETH or USDT"
        );

        //get fee from client

        

        if (addrCoin == address(0)) {
            require(Price == msg.value, "Error of the received ETH amount");
        } else {
            //transfer coins from client
            require(
                IERC20(addrCoin).transferFrom(msg.sender, address(this), Price),
                "Error transfer client coins"
            );
        }

        EnumTradeRequest.set(addrToken, 1);
    }

    function approveTradeToken(address addrToken, uint256 rank)
        external
        onlyAdmin
    {
        setTradeToken(addrToken, rank);
        EnumTradeRequest.remove(addrToken);
    }

    function trade(
        address addrTokenFrom,
        address addrTokenTo,
        uint256 amount
    ) external {
        require(
            MapTradeCoin[addrTokenFrom] != 0,
            "Error tokenFrom smart address"
        );
        require(MapTradeCoin[addrTokenTo] != 0, "Error tokenTo smart address");

        uint256 amountRest = MapWallet[msg.sender][addrTokenFrom];
        require(amountRest >= amount, "Insufficient funds");

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: addrTokenFrom,
                tokenOut: addrTokenTo,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);
        //console.log("amount=%s amountOut=%s",amount, amountOut);

        MapWallet[msg.sender][addrTokenFrom] = amountRest - amount;
        MapWallet[msg.sender][addrTokenTo] += amountOut;
    }

    function deposit(address addrToken, uint256 amount) external {
        require(addrToken != address(0), "Error token smart address");
        require(amount > 0, "Amount is zero");

        IERC20 smartToken = IERC20(addrToken);

        //transfer coins from client
        require(
            smartToken.transferFrom(msg.sender, address(this), amount),
            "Error transfer client tokens"
        );

        //add client balance tokens
        MapWallet[msg.sender][addrToken] += amount;
    }

    //withdraw by client
    function withdraw(address addrToken, uint256 amount) external {
        require(addrToken != address(0), "Error token smart address");
        uint256 amountRest = MapWallet[msg.sender][addrToken];
        require(amountRest >= amount, "Insufficient funds");

        IERC20 smartToken = IERC20(addrToken);
        require(
            smartToken.balanceOf(address(this)) >= amount,
            "Not enough tokens on the smart contract"
        );

        //send token
        smartToken.transfer(msg.sender, amount);
        MapWallet[msg.sender][addrToken] = amountRest - amount;
    }


    //view
    function getListingPrice(address addrCoin) public view returns (uint256) {
        return MapPrice[addrCoin];
    }

    function balanceOf(address addrClient, address addrToken)
        public
        view
        returns (uint256)
    {
        return MapWallet[addrClient][addrToken];
    }

    function rankTradeToken(address addrToken) public view returns (uint256) {
        return MapTradeCoin[addrToken];
    }

    function lengthTradeRequest() public view returns (uint256) {
        return EnumTradeRequest.length();
    }

    function listTradeRequest(uint256 startIndex, uint256 counts)
        public
        view
        returns (address[] memory Arr)
    {
        uint256 length = EnumTradeRequest.length();

        if (startIndex < length) {
            if (startIndex + counts > length) counts = length - startIndex;

            address key;
            Arr = new address[](counts);
            for (uint256 i = 0; i < counts; i++) {
                (key, ) = EnumTradeRequest.at(startIndex + i);
                Arr[i] = key;
            }
        }
    }

    function getPool(address tokenA, address tokenB)
        public
        view
        returns (address)
    {
        return swapFactory.getPool(tokenA, tokenB, poolFee);
    }

 
    function hasPool(address tokenA, address tokenB)
        public
        view
        returns (bool)
    {
        return getPool(tokenA, tokenB)!=address(0);
    }
    

    function poolPrice(address tokenIn, address tokenOut)
        external
        view
        returns (uint256 price)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(
            swapFactory.getPool(tokenIn, tokenOut, poolFee)
        );
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return (uint(sqrtPriceX96) * uint(sqrtPriceX96) * 1e18) >> (96 * 2);
    }
}

