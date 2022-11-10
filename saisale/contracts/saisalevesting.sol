// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SaiSaleVesting is Ownable {
    struct SItem {
        uint32 Expires; //timestamp
        uint96 Amount; //36+60 bits
        uint96 Price; //36+60 bits
        uint32 Vesting; //timestamp
    }

    mapping(bytes32 => SItem) private MapSale;
    mapping(address => uint256) private MapCoin;
    mapping(bytes32 => uint256) private MapBalance;

    constructor() {}

    function setCoin(address addressCoin, uint256 rate) external onlyOwner {
        MapCoin[addressCoin] = rate; // Rate for 1 USD
    }

    function _getKey(address addr, uint32 period)
        internal
        pure
        returns (bytes32 key)
    {
        key = keccak256(abi.encodePacked(addr, period));
    }

    function _getKeyBalance(
        address addr,
        address addrSale,
        uint32 period
    ) internal pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(addr, addrSale, period));
    }

    function setSale(
        address addressTokenSale,
        uint96 amount,
        uint96 price,
        uint32 periodStart,
        uint32 periodExpires,
        uint32 periodVesting
    ) external onlyOwner {
        bytes32 key = _getKey(addressTokenSale, periodStart);
        MapSale[key] = SItem(periodExpires, amount, price, periodVesting);
    }

    function buyToken(
        address addressTokenSale,
        uint32 periodStart,
        address addressCoin,
        uint256 amount
    ) external {
        require(
            block.timestamp >= periodStart,
            "Error, The sales Start period has not yet arrived"
        );
        require(amount > 0, "Amount is zero");

        bytes32 key = _getKey(addressTokenSale, periodStart);
        SItem storage info = MapSale[key];

        require(block.timestamp < info.Expires, "Error period Expires");
        require(info.Price > 0, "Sale Price is zero");
        require(info.Amount >= amount, "Not enough tokens on the Sale");

        uint256 rate = MapCoin[addressCoin];
        require(rate != 0, "Error coin");
        IERC20 smartCoin = IERC20(addressCoin);

        //transfer coins from client
        uint256 CoinAmount = (((amount * uint256(info.Price)) / 1e18) * rate) /
            1e18;
        require(
            smartCoin.transferFrom(msg.sender, address(this), CoinAmount),
            "Error transfer client coins"
        );

        //add client balance tokens
        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            periodStart
        );
        MapBalance[keyBalance] += amount;

        info.Amount -= uint96(amount);
    }

    //withdraw by client
    function withdraw(address addressTokenSale, uint32 periodStart) external {
        bytes32 key = _getKey(addressTokenSale, periodStart);
        SItem memory info = MapSale[key];

        //console.log("Block: %s, Expires: %s, Vesting: %s",block.timestamp,info.Expires, info.Expires);

        require(
            block.timestamp >= info.Vesting,
            "Error period Vesting"
        );

        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            periodStart
        );
        uint256 amount = MapBalance[keyBalance];
        IERC20 smartSale = IERC20(addressTokenSale);
        require(
            smartSale.balanceOf(address(this)) >= amount,
            "Not enough tokens on the smart contract"
        );
        smartSale.transfer(msg.sender, amount);
        MapBalance[keyBalance] = 0;
    }

    //withdraw by owner
    function withdrawCoins(address addressSmart) external onlyOwner {
        IERC20 smartCoin = IERC20(addressSmart);

        uint256 amount = smartCoin.balanceOf(address(this));
        smartCoin.transfer(msg.sender, amount);
    }

    function withdrawEth() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    //view
    function balanceOf(address addressTokenSale, uint32 periodStart)
        public
        view
        returns (uint256)
    {
        bytes32 keyBalance = _getKeyBalance(
            msg.sender,
            addressTokenSale,
            periodStart
        );
        return MapBalance[keyBalance];
    }

    function getSale(address addressTokenSale, uint32 periodStart)
        public
        view
        returns (SItem memory)
    {
        bytes32 key = _getKey(addressTokenSale, periodStart);
        return MapSale[key];
    }

    function currentBlock() public view returns (uint256) {
        return block.timestamp;
    }
}
