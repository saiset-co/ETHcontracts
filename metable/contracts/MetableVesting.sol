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

    ///@dev Storage info about coins for which user can buy tokens
    mapping(address => uint256) private MapCoin;

    uint48 constant PERCENT_100=100000;//100%

    ///@dev Storage info about token sale and vesting

    //Maps with key = keccak256keccak256(addressTokenSale,timeStart);
    mapping(bytes32 => SSale) private MapSale;          //token sales
    mapping(bytes32 => SVesting) private MapVesting;    //vesting params

    //Maps with key = keccak256(msg.sender, addressTokenSale,timeStart);
    mapping(bytes32 => uint256) private MapPurchase;    //the number of all tokens purchased
    mapping(bytes32 => uint256) private MapWithdraw;    //the number of all tokens withdrawn
    

    constructor() {}

    /**
    * @dev Setting a list of coins for which user can buy tokens
    * 
     * @param addressCoin The coin address for which the token is bought
     * @param rate The exchange rate to one dollar
    */
    function setCoin(address addressCoin, uint256 rate) external onlyOwner {
        MapCoin[addressCoin] = rate; // Rate for 1 USD
    }

    ///@dev Sale key
    function _getKey(address addr, uint48 time)
        internal
        pure
        returns (bytes32 key)
    {
        key = keccak256(abi.encodePacked(addr, time));
    }

    ///@dev The user's wallet balance key
    function _getKeyBalance(
        address addr,
        address addrSale,
        uint48 time
    ) internal pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(addr, addrSale, time));
    }

    /**
    * @dev Setting token sale parameters
    * 
     * @param addressTokenSale The token of sale
     * @param amount The number of tokens
     * @param price The price for one token
     * @param timeStart The start sale date
     * @param timeExpires The end sale date
     * @param timeCliff The end of cliff time
     * @param vestingPeriodCounts The number of vesting periods
     * @param vestingPeriod The number of seconds of one vesting period
     * @param vestingFirst The percentage of vesting of the first period
    */
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
        require(block.timestamp <= timeStart,"Error timeStart");
        require(timeStart<=timeExpires,"Error timeExpires");
        require(timeExpires<=timeCliff,"Error timeCliff");
      

        bytes32 key = _getKey(addressTokenSale, timeStart);
        MapSale[key] = SSale(timeExpires, amount, price);
        MapVesting[key] = SVesting(timeCliff,vestingPeriodCounts,vestingPeriod,vestingFirst);
    }

    /**
    * @dev Purchase of tokens
    * 
     * @param addressTokenSale The token of sale
     * @param timeStart The start sale date
     * @param addressCoin The coin address for which the token is bought
     * @param amount The number of tokens
    */
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
        require(info.Expires>0, "Error timeStart");

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

    /**
    * @dev Withdraw tokens by the user
    * 
     * @param addressTokenSale The token of sale
     * @param timeStart The start date
    */
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

    /**
    * @dev Withdraw the entire balance of coins on a smart contract (coins for which tokens were bought)
    * 
    * @param addressSmart The address of the smart contract in which the price is estimated
    */
    function withdrawCoins(address addressSmart) external onlyOwner {
        IERC20 smartCoin = IERC20(addressSmart);

        uint256 amount = smartCoin.balanceOf(address(this));
        smartCoin.safeTransfer(msg.sender, amount);
    }

    /**
    * @dev Withdraw the entire ETH balance on a smart contract
    */
    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //View

    /**
     * @dev Retrieves the number of tokens that are purchased by the user but are in the wallet on the smart contract
     * 
     * @param addressTokenSale The token of sale
     * @param timeStart The start date
     * @return The balance
     */
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



    /**
     * @dev Retrieves information about the token sale
     * 
     * @param addressTokenSale The token of sale
     * @param timeStart The start date
     * @return The info {SSale},{SVesting}
     */
    function getSale(address addressTokenSale, uint48 timeStart)
        public
        view
        returns (SSale memory, SVesting memory)
    {
        bytes32 key = _getKey(addressTokenSale, timeStart);
        return (MapSale[key], MapVesting[key]);
    }


}
