// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SmartOnly is Ownable {
    mapping(address => bool) internal mapAllow;

    //Throws if called by any account other than the smart.
    modifier onlySmart() {
        require(mapAllow[msg.sender], "Error smart allower");
        _;
    }

    ///@dev Setting the address of the smart contract that manages balances
    function setSmart(address addr) public onlyOwner {
        mapAllow[addr] = true;
    }

    ///@dev Removing the address of the smart contract that manages balances
    function unsetSmart(address addr) public onlyOwner {
        mapAllow[addr] = false;
    }
    

}
