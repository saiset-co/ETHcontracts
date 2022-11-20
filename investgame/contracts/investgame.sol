// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./Admin.sol";
import "./KeyList.sol";

//import "hardhat/console.sol";

contract InvestGame is Admin {
    mapping(address => uint256) private MapPrice;
    mapping(address => uint256) private MapFee;
    mapping(address => string) private MapTradeCoin;

    //       client             token      amount
    mapping(address => mapping(address => uint256)) private MapWallet;

    using KeyList for KeyList.ListItems;
    KeyList.ListItems private ListTradeRequest;


    uint24 public constant poolFee = 3000; //set the pool fee to 0.3%.
    //ISwapRouter public immutable swapRouter;
    ISwapRouter public swapRouter;
    IUniswapV3Factory swapFactory;
    address addrETH;
    address addrUSDT;

    struct SRequesInfo {
        uint32 key;
        address token;
    }



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
    ) public onlyAdmin initializer {
        swapFactory = IUniswapV3Factory(_factory);
        swapRouter = ISwapRouter(_swapRouter);
        addrETH = _addrETH;
        addrUSDT = _addrUSDT;
    }

    function setListingPrice(address addrCoin, uint256 price) public onlyAdmin {
        MapPrice[addrCoin] = price;
    }

    function setTradeToken(address addrToken, string memory rank)
        public
        onlyAdmin
    {
        require(addrToken != address(0), "Error token smart address");
        require(isEmptyStr(rank) == false, "Error, rank length is zero");

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

        MapFee[addrCoin] += Price;

        ListTradeRequest.add(uint160(addrToken));
    }

    function approveTradeToken(uint32 key, string memory rank)
        external
        onlyAdmin
    {
        address addrToken=address(uint160(ListTradeRequest.get(key)));
        setTradeToken(addrToken, rank);
        ListTradeRequest.remove(key);
    }

    function trade(
        address addrTokenFrom,
        address addrTokenTo,
        uint256 amount
    ) external {
        require(
            isEmptyStr(MapTradeCoin[addrTokenFrom]) == false,
            "Error tokenFrom smart address"
        );
        require(
            isEmptyStr(MapTradeCoin[addrTokenTo]) == false,
            "Error tokenTo smart address"
        );

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

    //withdraw by admin
    function withdrawListFee(
        address addrToken,
        address addrTo,
        uint256 amount
    ) external onlyAdmin {
        require(addrTo != address(0), "Error To address");
        require(MapFee[addrToken]>=amount,"Withdraw amount exceeds fee balance");

        if (addrToken == address(0)) {
            payable(addrTo).transfer(amount);
        } else {
            IERC20(addrToken).transfer(addrTo, amount);
        }

        MapFee[addrToken]-=amount;
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

    function balanceFee(address addrToken)
        public
        view
        returns (uint256 amount)
    {
        return MapFee[addrToken];
    }

    function rankTradeToken(address addrToken)
        public
        view
        returns (string memory)
    {
        return MapTradeCoin[addrToken];
    }

   function listTradeRequest(uint32 startKey, uint32 counts)
        public
        view
        returns (SRequesInfo[] memory Arr)
    {
        (KeyList.SItemValue[] memory KeyArr, uint32 retCount) = ListTradeRequest.getItems(startKey,counts);

        if (retCount>0) {
            Arr = new SRequesInfo[](retCount);
            for (uint256 i = 0; i < retCount; i++) {
                Arr[i].key = KeyArr[i].key;
                Arr[i].token = address(uint160(KeyArr[i].value));
            }
        }
    }

/*
   struct SDebug
   {
        uint32 first;
        uint32 last;
        KeyList.SItemValue[] Arr;
   }

   function listTradeRequest(uint32 startKey, uint32 counts)
        public
        view
        returns (SDebug memory Ret)
    {
        (KeyList.SItemValue[] memory KeyArr, uint32 retCount) = ListTradeRequest.getItems(startKey,counts);
        Ret.first=ListTradeRequest.first;
        Ret.last=ListTradeRequest.last;

        if (retCount>0) {
            Ret.Arr = new KeyList.SItemValue[](retCount);
            for (uint256 i = 0; i < retCount; i++) {
                Ret.Arr[i] = KeyArr[i];
                Ret.Arr[i].value=111;
            }
        }
    }
//*/


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
        return getPool(tokenA, tokenB) != address(0);
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

    //util
    function isEmptyStr(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
}
