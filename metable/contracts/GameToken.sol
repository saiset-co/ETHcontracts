// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SmartOnly.sol";


contract GameToken is ERC20Burnable, SmartOnly {
    using SafeERC20 for ERC20;

    ///@dev Total volume of tokens for sale
    uint256 public SaleAmount;
    ///@dev The price of one token in ETH
    uint256 public SalePrice;

    ///@dev Storage info about coins for which user can buy tokens
    mapping(address => uint256) private MapToken;

    constructor() ERC20("Metable token", "MTB") {}


     /**
     * @dev Token transfer, called from other smart contracts
     * 
     * @param from The sender's address
     * @param to The recipient's address
     * @param amount The amount of token
     */
    function SmartTransferTo(address from, address to, uint256 amount)
        external onlySmart
        returns (bool)
    {
        _transfer(from, to, amount);

        return true;
    }

    /**
     * @dev Mint tokens to this smart addres
     * 
     * Emits a {Transfer} event.
     * 
     * @param amount The amount of token
     */
    function Mint(uint256 amount) external onlyOwner {
        _mint(address(this), amount);
    }

    /**
     * @dev Mint tokens to address
     * 
     * Emits a {Transfer} event.
     * 
     * @param to The recipient's address
     * @param amount The amount of token
     */
    function MintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

     /**
     * @dev Transfer tokens from smart contract to address
     * 
     * Emits a {Transfer} event.
     * 
     * @param to The recipient's address
     * @param amount The amount of token
     */
    function transferToken(address to, uint256 amount) external onlyOwner {
        _transfer(address(this),to, amount);
    }

     /**
     * @dev Setting the common volume of token sales and set ETH prices
     * 
     * @param amount The amount of token
     * @param price The price for one token
     */
    function setSale(uint256 amount, uint256 price) external onlyOwner {
        SaleAmount = amount;
        SalePrice = price;
    }
    

     /**
     * @dev Buying tokens for ETH
     * The number of tokens that the user wants to buy is calculated automatically based on the ETH sent
     */
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

     /**
     * @dev Setting the price of other coins
     * 
     * @param addressSmart The address of the smart contract in which the price is estimated
     * @param price The price for one token
     */
    function setSmartSale(address addressSmart, uint256 price) external onlyOwner {
        MapToken[addressSmart]=price;
    }

     /**
     * @dev Buying tokens for coins
     * 
     * @param addressSmart The address of the smart contract in which the price is estimated
     * @param amount The number of tokens that the user wants to buy
     */
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
        smartToken.safeTransferFrom(msg.sender, address(this), TokenAmount);

        //transfer to client
        SaleAmount -= amount;
        _transfer(address(this), msg.sender, amount);
    }


    //withdraw

    /**
    * @dev Withdraw the entire ETH balance on a smart contract
    */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    /**
    * @dev Withdraw the entire balance of coins on a smart contract
    * 
     * @param addressSmart The address of the smart contract in which the price is estimated
    */
    function withdrawToken(address addressSmart) external onlyOwner
    {
        ERC20 smartToken=ERC20(addressSmart);

        uint256 amount=smartToken.balanceOf(address(this));
        smartToken.transfer(msg.sender, amount);
    }

}
