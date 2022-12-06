// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract UndeadsStaking is Ownable
{
    using SafeERC20 for IERC20;


    uint32 currentSeasonId;
    uint48 timeStakeStart;
    uint48 timeStakeEnd;
    struct SSeason{
        uint256 poolReward;
        uint256 poolStake;
    }

    //        id   -> {SSeason}
    mapping(uint256 => SSeason) private MapSeason;

    struct SSession{
        uint32 idSeason;
        uint48 Start; //timestamp
        uint48 End;   //timestamp
        uint128 Amount;  //68+60 bits
        uint128 Stake;   //68+60 bits
        uint128 Withdraw;//68+60 bits
    }

    //      user    -> idSession -> {SSession}
    mapping(address => mapping(uint256 => SSession)) private MapSession;
    mapping(address => uint256) private MapSessionCounter;
    



    IERC20 smartUDS;

    constructor(address addrUDS)
    {
        smartUDS=IERC20(addrUDS);
    }


    function setSeason(uint256 amount,uint48 timeStart,uint48 timeEnd)  external onlyOwner
    {
        require(amount>0,"Error, zero amount");

        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), amount);

        currentSeasonId++;
        timeStakeStart=timeStart;
        timeStakeEnd=timeEnd;
        MapSeason[currentSeasonId]=SSeason(amount,0);
        
    }



    function stake(uint256 amount,uint256 periodDay)  external
    {
        require(amount>0,"Error, zero amount");
        //require(periodDay>0,"Error, zero periodDay");
        require(block.timestamp > timeStakeStart, "Error start staking time");
        require(block.timestamp < timeStakeEnd, "Error end staking time");

        uint256 amountStake;
        if(periodDay==30)
            amountStake=amount*1;
        else
        if(periodDay==60)
            amountStake=amount*5;
        else
        if(periodDay==90)
            amountStake=amount*10;
        if(periodDay==120)
            amountStake=amount*24;
        else
        if(periodDay==180)
            amountStake=amount*40;
        else
        if(periodDay==365)
            amountStake=amount*75;
        else
        if(periodDay==730)
            amountStake=amount*170;
        else {
            revert("Error periodDay params");
        }

        amountStake=amountStake*periodDay/100/360;


        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), amount);


        MapSessionCounter[msg.sender]++;
        uint256 id=MapSessionCounter[msg.sender];
        SSession storage Stake=MapSession[msg.sender][id];

        Stake.idSeason = currentSeasonId;
        Stake.Start = uint48(block.timestamp);
        Stake.End = uint48(block.timestamp + periodDay * 86400);
        Stake.Amount = uint128(amount);
        Stake.Stake =  uint128(amountStake);
        Stake.Withdraw = 0;

        SSeason storage Season = MapSeason[currentSeasonId];
        Season.poolStake+=amountStake;
    }



    function unstake(uint32 sessionId)  external
    {
        SSession memory Stake=MapSession[msg.sender][sessionId];

        require(block.timestamp > Stake.End, "Error unstaking time");

        uint256 amount=Stake.Amount;
        require(amount>0,"Error sessionId");

        //calc reward
        amount += _getReward(Stake);

        //transfer coins to client
        smartUDS.safeTransfer(msg.sender, amount);

        delete MapSession[msg.sender][sessionId];
    }


    function reward(uint32 sessionId)  external
    {
        SSession storage Stake=MapSession[msg.sender][sessionId];
        require(Stake.idSeason>0,"Error Id");

        if(Stake.idSeason==currentSeasonId)
        {
            require(block.timestamp > timeStakeEnd, "Error reward time for current season");
        }


        //calc reward
        uint256 amount = _getReward(Stake);
        require(amount>Stake.Withdraw,"There is nothing to withdraw reward");
        uint256 delta = amount-Stake.Withdraw;

        //transfer coins to client
        smartUDS.safeTransfer(msg.sender, delta);

        Stake.Withdraw += uint128(delta);
    }

    

    function _getReward(SSession memory Stake) private view returns (uint256)
    {
        SSeason memory Season = MapSeason[Stake.idSeason];
        uint256 Price=1e18*Season.poolReward/Season.poolStake;

        uint256 delta_time=block.timestamp-Stake.Start;
        uint256 period=Stake.End-Stake.Start;
        uint256 percent=100000*delta_time/period;
        if(percent>100000)
            percent=100000;
        
        
        return Stake.Stake*Price*percent/100000/1e18;
    }






    //View
    function rewardOf(address addr,uint32 sessionId)
        public
        view
        returns (uint256)
    {
        SSession memory Stake=MapSession[addr][sessionId];

        return _getReward(Stake);
    }

    function balanceOf(address addr,uint32 sessionId)
        public
        view
        returns (uint256)
    {
        SSession memory Stake=MapSession[addr][sessionId];
        return Stake.Amount;
    }

    function lengthSessions(address addr)
        public
        view
        returns (uint256)
    {
        return MapSessionCounter[addr];
    }

    function listSessions(address addr,uint256 startIndex,uint256 counts)
        public
        view
        returns (SSession [] memory Arr)
    {
        uint256 length=MapSessionCounter[addr];
        if(startIndex<1)
            startIndex=1;
        if (startIndex <= length) 
        {
            if (startIndex + counts > length + 1) counts = length + 1 - startIndex;

            Arr = new SSession[](counts);
            for (uint256 i = 0; i < counts; i++) 
            {
                Arr[i]=MapSession[addr][startIndex+i];
            }
        }
    }
}


