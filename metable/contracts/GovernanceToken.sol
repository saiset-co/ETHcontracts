// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SmartOnly.sol";

contract GovernanceToken is ERC20, SmartOnly {
 
    constructor() ERC20("Governance token", "GVR") {}

 
     /**
     * @dev Token transfer, called from other smart contracts
     * 
     * @param from The sender's address
     * @param to The recipient's address
     * @param amount The amount of token
     */
    function SmartTransferTo(address from, address  to, uint256 amount)
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
    * @dev Withdraw the entire ETH balance on a smart contract
    */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
