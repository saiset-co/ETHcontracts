// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract UndeadsStaking is Ownable
{
    using SafeERC20 for IERC20;

    struct SWallet{
        uint96 Amount; //36+60 bits
        uint96 Withdraw; //36+60 bits
        uint32 Start; //timestamp
        uint32 Period;
    }

    uint256 poolReward;
    uint256 poolStaking;

    IERC20 smartUDS;
    mapping(address => SWallet) private MapWallet;

    constructor(address addrUDS)
    {
        smartUDS=IERC20(addrUDS);
    }


    //function setStaking()  external onlyOwner    {   }


    function addReward(uint256 amount)  external onlyOwner
    {
        require(amount>0,"Error, zero amount");
        
        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), amount);
        poolReward+=amount;
    }

    function stake(uint256 amount,uint256 period)  external
    {
        require(amount>0,"Error, zero amount");
        require(period>0,"Error, zero period");

        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), amount);

        SWallet storage info=MapWallet[msg.sender];
        require(info.Amount==0,"Error, double staking");

        info.Amount = uint96(amount);
        info.Start = uint32(block.timestamp);
        info.Period = uint32(period);

        poolStaking+=amount;
    }

    function unstake()  external
    {
        SWallet memory info=MapWallet[msg.sender];

        require(block.timestamp > info.Start+info.Period, "Error unstaking time");

        uint256 amount=info.Amount;
        require(amount>0,"Zero amount");

        //calc reward
        amount += _getReward(msg.sender);

        //transfer coins to client
        smartUDS.safeTransfer(msg.sender, amount);

        delete MapWallet[msg.sender];
    }

    function reward()  external
    {
        SWallet memory info=MapWallet[msg.sender];

        //calc reward
        uint256 amount = _getReward(msg.sender);
        require(amount>info.Withdraw,"There is nothing to withdraw reward");

        uint256 delta = amount-info.Withdraw;

        //transfer coins to client
        smartUDS.safeTransfer(msg.sender, delta);

        MapWallet[msg.sender].Withdraw += uint96(delta);
    }
    

    function _getReward(address addr) private view returns (uint256)
    {
        uint256 K=1e18*poolReward/poolStaking;

        SWallet memory info=MapWallet[addr];
        return info.Amount*K/1e18;
    }




    //View
    function balanceOf(address addr)
        public
        view
        returns (uint256)
    {
        return MapWallet[addr].Amount;
    }

    function rewardOf(address addr)
        public
        view
        returns (uint256)
    {
        return _getReward(addr);
    }

}

