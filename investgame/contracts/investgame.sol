// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";


//import "hardhat/console.sol";

contract InvestGame is Ownable {
    uint256 public Price;
    mapping(address => uint256) private MapTradeCoin;

    //       client             token      amount
    mapping(address => mapping(address => uint256)) private MapWallet;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private EnumTradeRequest;

    ISwapRouter public immutable swapRouter;
    //ISwapRouter public swapRouter; //immutable
    uint24 public constant poolFee = 3000; //set the pool fee to 0.3%.

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    //function setSwapRouter(ISwapRouter _swapRouter) public onlyOwner {
    //    swapRouter = _swapRouter;
    //}

    function setListingPrice(uint256 price) public onlyOwner {
        Price = price;
    }

    function setTradeToken(address addrToken, uint256 rank) public onlyOwner {
        require(addrToken != address(0), "Error token smart address");
        require(rank > 0, "Error, rank is zero");

        TransferHelper.safeApprove(addrToken, address(swapRouter), 1e36);

        MapTradeCoin[addrToken] = rank;
    }

    function delTradeToken(address addrToken) external onlyOwner {
        require(addrToken != address(0), "Error token smart address");
        delete MapTradeCoin[addrToken];
    }

    function requestTradeToken(address addrToken) external {
        require(Price > 0, "Error, listing Price is zero");
        require(addrToken != address(0), "Error token smart address");
        //todo - check UniSwap

        //todo - get fee from client ?? Eth or ERC20

        EnumTradeRequest.set(addrToken, 1);
    }

    function approveTradeToken(address addrToken, uint256 rank)
        external
        onlyOwner
    {
        setTradeToken(addrToken, rank);
        EnumTradeRequest.remove(addrToken);
    }

    function trade(
        address addrTokenFrom,
        address addrTokenTo,
        uint256 amount
    ) external {
        require(addrTokenFrom != address(0), "Error tokenFrom smart address");
        require(addrTokenTo != address(0), "Error tokenTo smart address");

        uint256 amountRest = MapWallet[msg.sender][addrTokenFrom];
        require(amountRest >= amount, "Insufficient funds");

        //--------------------------todo test UniSwap

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
                amountOutMinimum: 0, //!! - устанавливаем на ноль,но в продакшене это дает определенный риск. Для реального проекта, это значение должно быть рассчитано с использованием нашего SDK или оракула цен в сети — это помогает защититься от получения нехарактерно плохих цен для сделки ,которые могут являться следствием работы фронта или любого другого типа манипулирования ценой. 
                sqrtPriceLimitX96: 0 //!! - устанавливаем в 0 — это делает этот парамент неактивным.В продакшене, это значение можно использовать для установки предела цены, по которой своп будет проходить в пуле.
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);

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
}
