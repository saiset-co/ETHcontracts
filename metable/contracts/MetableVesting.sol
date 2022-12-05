// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



//import "hardhat/console.sol";

contract MetableVesting is Ownable {
    using SafeERC20 for IERC20;

    struct SSale{
        uint48 Expires; //timestamp
        uint104 Amount; //44+60 bits
        uint104 Price; //36+60 bits
    }
    struct SVesting {
        uint48 Cliff; //timestamp
        uint48 Counts;
        uint48 Period;//in sec
        uint48 First;//100000 = 100%
    }

    mapping(address => uint256) private MapCoin;

    uint48 constant PERCENT_100=100000;//100%


    mapping(bytes32 => SSale) private MapSale;
    mapping(bytes32 => SVesting) private MapVesting;
    mapping(bytes32 => uint256) private MapPurchase;
    mapping(bytes32 => uint256) private MapWithdraw;
    

    constructor() {}

    function setCoin(address addressCoin, uint256 rate) external onlyOwner {
        MapCoin[addressCoin] = rate; // Rate for 1 USD
    }

    function _getKey(address addr, uint48 time)
        internal
        pure
        returns (bytes32 key)
    {
        key = keccak256(abi.encodePacked(addr, time));
    }

    function _getKeyBalance(
        address addr,
        address addrSale,
        uint48 time
    ) internal pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(addr, addrSale, time));
    }

    function setSale(
        address addressTokenSale,
        uint104 amount,
        uint104 price,
        uint48 timeStart,
        uint48 timeExpires,
        uint48 timeCliff,
        uint48 vestingPeriodCounts,
        uint48 vestingPeriod,
        uint48 vestingFirst//100000 = 100%

    ) external onlyOwner {
        require(price>0,"Error, zero price");
        require(vestingPeriodCounts>=2,"The minimum value of the vesting Period counts should be 2");
        

        bytes32 key = _getKey(addressTokenSale, timeStart);
        MapSale[key] = SSale(timeExpires, amount, price);
        MapVesting[key] = SVesting(timeCliff,vestingPeriodCounts,vestingPeriod,vestingFirst);
    }

    function buyToken(
        address addressTokenSale,
        uint48 timeStart,
        address addressCoin,
        uint256 amount
    ) external {
        require(
            block.timestamp >= timeStart,
            "Error, The sales Start time has not yet arrived"
        );
        require(amount > 0, "Amount is zero");

        bytes32 key = _getKey(addressTokenSale, timeStart);
        SSale storage info = MapSale[key];

        require(block.timestamp < info.Expires, "Error time Sale Expires");
        require(info.Price > 0, "Sale Price is zero");
        require(uint256(info.Amount) >= amount, "Not enough tokens on the Sale");

        uint256 rate = MapCoin[addressCoin];
        require(rate != 0, "Error coin");
        IERC20 smartCoin = IERC20(addressCoin);

        //transfer coins from client
        uint256 coinAmount = (((amount * uint256(info.Price)) / 1e18) * rate) / 1e18;
        smartCoin.safeTransferFrom(msg.sender, address(this), coinAmount);


        //add client balance tokens
        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            timeStart
        );
        MapPurchase[keyBalance] += amount;

        info.Amount -= uint104(amount);
    }

    //withdraw by client
    function withdraw(address addressTokenSale, uint48 timeStart) external {
        bytes32 key = _getKey(addressTokenSale, timeStart);
        SVesting memory info = MapVesting[key];

        //console.log("Block: %s, Expires: %s, Cliff: %s",block.timestamp,info.Expires, info.Expires);

        require(
            block.timestamp >= info.Cliff,
            "Error time Cliff"
        );

        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            timeStart
        );
        
        uint256 balance = MapPurchase[keyBalance];
        uint256 balanceWithdraw = MapWithdraw[keyBalance];

        uint48 delta_periods = (uint48(block.timestamp)-info.Cliff)/info.Period;
        uint48 percent = info.First + delta_periods*(PERCENT_100-info.First)/(info.Counts-1);
        if(percent>PERCENT_100)
            percent = PERCENT_100;
        uint256 amount = balance * percent / PERCENT_100;

        require(amount > balanceWithdraw,"There is nothing to withdraw");
        uint256 delta_amount = amount - balanceWithdraw;


        IERC20 smartSale = IERC20(addressTokenSale);
        smartSale.safeTransfer(msg.sender, delta_amount);
        MapWithdraw[keyBalance] += delta_amount;
    }


    //withdraw by owner
    function withdrawCoins(address addressSmart) external onlyOwner {
        IERC20 smartCoin = IERC20(addressSmart);

        uint256 amount = smartCoin.balanceOf(address(this));
        smartCoin.safeTransfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //View
    function balanceOf(address addressTokenSale, uint48 timeStart)
        public
        view
        returns (uint256)
    {
        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            timeStart
        );
        return MapPurchase[keyBalance] - MapWithdraw[keyBalance];
    }


    function getSale(address addressTokenSale, uint48 timeStart)
        public
        view
        returns (SSale memory, SVesting memory)
    {
        bytes32 key = _getKey(addressTokenSale, timeStart);
        return (MapSale[key], MapVesting[key]);
    }


}
