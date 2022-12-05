// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SmartOnly.sol";

contract GovernanceToken is ERC20, SmartOnly {
 
    constructor() ERC20("Governance token", "GVR") {}

 
    function SmartTransferTo(address from, address  to, uint256 amount)
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

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
