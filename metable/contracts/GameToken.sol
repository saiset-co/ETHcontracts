// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SmartOnly.sol";

contract GameToken is ERC20, SmartOnly {
    uint256 public SaleAmount;
    uint256 public SalePrice;

    mapping(address => uint256) private MapToken;

    constructor() ERC20("Metable token", "MTB") {}


    function SmartTransferTo(address from, address to, uint256 amount)
        external onlySmart
        returns (bool)
    {
        _transfer(from, to, amount);

        return true;
    }

    function Mint(uint256 amount) external onlyOwner {
        _mint(address(this), amount);
    }

    function MintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function transferToken(address to, uint256 amount) external onlyOwner {
        _transfer(address(this),to, amount);
    }

    function setSale(uint256 amount, uint256 price) external onlyOwner {
        SaleAmount = amount;
        SalePrice = price;
    }

    function buyToken() external payable {
        require(SalePrice > 0, "Sale Price is zero");

        uint256 needAmount = 1e18 * msg.value / SalePrice;
        require(needAmount > 0, "Need Amount is zero");

        require(
            SaleAmount >= needAmount,
            "Not enough tokens on the Sale"
        );
        require(
            balanceOf(address(this)) >= needAmount,
            "Not enough tokens on the smart contract"
        );

        SaleAmount -= needAmount;
        _transfer(address(this), msg.sender, needAmount);
    }

    //token buy
    function setSmartSale(address addressSmart, uint256 price) external onlyOwner {
        MapToken[addressSmart]=price;
    }

    function buyToken2(address addressSmart,uint256 amount) external {
        require(amount > 0, "Amount is zero");
        //require(SalePrice > 0, "Sale Price is zero");
        require(
            SaleAmount >= amount,
            "Not enough tokens on the Sale"
        );
        require(
            balanceOf(address(this)) >= amount,
            "Not enough tokens on the smart contract"
        );

        uint256 Price = MapToken[addressSmart];
        require(Price>0,"Error smart token address");

        ERC20 smartToken=ERC20(addressSmart);

        //transfer from client
        uint256 TokenAmount = Price*amount/1e18;
        require(smartToken.transferFrom(msg.sender, address(this), TokenAmount),"Error transfer clients coins");

        //transfer to client
        SaleAmount -= amount;
        _transfer(address(this), msg.sender, amount);
    }


    //withdraw

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address addressSmart) external onlyOwner
    {
        ERC20 smartToken=ERC20(addressSmart);

        uint256 amount=smartToken.balanceOf(address(this));
        smartToken.transfer(msg.sender, amount);
    }

}
