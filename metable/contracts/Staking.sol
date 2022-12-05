// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface ISmartToken {
    function SmartTransferTo(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Staking is Ownable {
    mapping(address => uint256) internal mapStake;
    ISmartToken public smartToken;
    uint256 public TotalStake;

    constructor(address addrToken) {
        smartToken = ISmartToken(addrToken);
    }

    function setStaking(uint256 amount) external {
        require(amount > 0, "Amount is zero");

        //Get Token from client
        require(
            smartToken.SmartTransferTo(msg.sender, address(this), amount),
            "Error transfer Token"
        );

        mapStake[msg.sender] += amount;
        TotalStake += amount;
    }

    function removeStaking(uint256 amount) external {
        require(amount > 0, "Amount is zero");

        uint256 Balance = mapStake[msg.sender];
        require(Balance >= amount, "Insufficient stake funds");

        mapStake[msg.sender] = Balance - amount;
        TotalStake -= amount;

        //Send Token to client
        require(
            smartToken.SmartTransferTo(address(this), msg.sender, amount),
            "Error transfer Token"
        );
    }

    function getStakingAmount(address addr) public view returns (uint256) {
        return mapStake[addr];
    }
}
