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
        uint48 Expires;//timestamp
        uint104 Amount;//44+60 bits
        uint104 Price; //44+60 bits
    }

    mapping(bytes32 => SItem) private MapSale;

    mapping(address => uint256) private MapCoin;

    constructor() {}

    function setCoin(address addressCoin, uint256 rate) external onlyOwner {
        MapCoin[addressCoin] = rate; // Rate for 1 USD
    }

    function setSale(
        address addressTokenSale,
        uint48 periodStart,
        uint48 periodExpires,
        uint104 amount,
        uint104 price
    ) external onlyOwner {
        bytes32 key = keccak256(
            abi.encodePacked(addressTokenSale, periodStart)
        );
        MapSale[key] = SItem(periodExpires, amount, price);
    }

    function buyToken(
        address addressTokenSale,
        uint48 periodStart,
        address addressCoin,
        uint256 amount
    ) external {
        require(block.timestamp >= periodStart, "Error period Start");
        require(amount > 0, "Amount is zero");

        bytes32 key = keccak256(
            abi.encodePacked(addressTokenSale, periodStart)
        );
        SItem storage info = MapSale[key];

        require(info.Expires >= block.timestamp, "Error period Expires");
        require(info.Price > 0, "Sale Price is zero");
        require(info.Amount >= amount, "Not enough tokens on the Sale");

        IERC20 smartSale = IERC20(addressTokenSale);
        require(
            smartSale.balanceOf(address(this)) >= amount,
            "Not enough tokens on the smart contract"
        );

        uint256 rate = MapCoin[addressCoin];
        require(rate != 0, "Error coin");
        IERC20 smartCoin = IERC20(addressCoin);

        //transfer coins from client
        uint256 CoinAmount = amount * uint256(info.Price) / 1e18 * rate / 1e18;
        require(
            smartCoin.transferFrom(msg.sender, address(this), CoinAmount),
            "Error transfer clients coins"
        );

        //transfer tokens to client
        smartSale.transfer(msg.sender, amount);
        info.Amount -= uint104(amount);
    }

    //view
    function getSale(address addressTokenSale, uint48 periodStart)
        public
        view
        returns (SItem memory)
    {
        bytes32 key = keccak256(
            abi.encodePacked(addressTokenSale, periodStart)
        );
        return MapSale[key];
    }

    //withdraw
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawCoins(address addressSmart) external onlyOwner {
        IERC20 smartCoin = IERC20(addressSmart);

        uint256 amount = smartCoin.balanceOf(address(this));
        smartCoin.transfer(msg.sender, amount);
    }
}
