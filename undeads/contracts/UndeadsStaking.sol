// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract UndeadsStaking is Ownable
{
    uint256 constant internal PERCENT100=1e18;

    uint48 public timeStartPeriod;//time stamp
    uint32 public periodDelta;//delta sec
    uint32 public windowEnd;  //delta sec

    uint32 public countAllPeriods;   //all periods
    uint32 public countFirstsPeriods;//count boost staking period
    uint256 public percentFirstsPeriods;

    uint256 public allReward;
    uint256 public poolStake;


    struct SSession{
        uint48 Start;    //timestamp
        uint48 End;      //timestamp
        uint128 Body;    //68+60 bits
        uint128 Stake;   //68+60 bits
        uint128 Withdraw;//68+60 bits
        uint256 idNFT;
    }
    struct SInfoSession{
        SSession info;
        uint256 reward;
    }


    //      user    -> idSession -> {SSession}
    mapping(address => mapping(uint256 => SSession)) internal MapSession;
    mapping(address => uint256) internal MapSessionCounter;

    constructor()
    {
        /*
        periodDelta=86400;
        countFirstsPeriods=60;
        percentFirstsPeriods=uint32(PERCENT100*10/30/100);

        windowEnd=30;
        */
    }



    //_percentFirstsPeriods 100% = 1e9
    function setup(uint256 _amount, uint48 _startPeriods, uint32 _periodDelta, uint32 _windowEnd, uint32 _countAllPeriods, uint32 _countFirstsPeriods,uint32 _percentFirstsPeriods)  external onlyOwner
    {
        require(_amount>0,"Error, zero amount");
        require(_startPeriods>0,"Error, zero startPeriods");
        require(_periodDelta>0,"Error, zero periodDelta");
        require(_countAllPeriods>0,"Error, zero countAllPeriods");
        
        allReward = _amount;
        timeStartPeriod=_startPeriods;
        periodDelta=_periodDelta;
        windowEnd=_windowEnd;

        countAllPeriods=_countAllPeriods;
        countFirstsPeriods=_countFirstsPeriods;
        percentFirstsPeriods=_percentFirstsPeriods*PERCENT100/1e9;
    }

    function setPeriod(uint32 _periodDelta)  external onlyOwner
    {
        require(_periodDelta>0,"Error, zero periodDelta");
        periodDelta=_periodDelta;
    }


    //Lib

    function _stake(uint256 _amountBody,uint256 _amountEffect, uint256 _periodDay, uint256 idNFT)  internal
    {

        uint256 CurTimePeriod=_GetCurPeriodTime();

        require(_amountBody>0,"Error, zero amount");
        if(block.timestamp >= CurTimePeriod + windowEnd)
        {
            CurTimePeriod += periodDelta;
        }


        uint256 PercentYear;
        if(_periodDay==30)
            PercentYear=1;
        else
        if(_periodDay==60)
            PercentYear=5;
        else
        if(_periodDay==90)
            PercentYear=10;
        else
        if(_periodDay==120)
            PercentYear=24;
        else
        if(_periodDay==180)
            PercentYear=40;
        else
        if(_periodDay==365)
            PercentYear=75;
        else
        if(_periodDay==730)
            PercentYear=170;
        else {
            revert("Error _periodDay params");
        }

        uint256 amountStake=_amountEffect*PercentYear/100/360;


        MapSessionCounter[msg.sender]++;
        uint256 id=MapSessionCounter[msg.sender];
        SSession storage Stake=MapSession[msg.sender][id];

        Stake.Start = uint48(CurTimePeriod);
        Stake.End = uint48(CurTimePeriod + _periodDay * 86400);
        Stake.Body = uint128(_amountBody);
        Stake.Stake =  uint128(amountStake);
        Stake.Withdraw = 0;
        Stake.idNFT = idNFT;

        poolStake+=amountStake;
    }

    function _GetCurPeriodTime() internal view returns(uint256)
    {
        require(block.timestamp > timeStartPeriod, "Error start staking time");
        uint256 PeriodNum = (block.timestamp-timeStartPeriod)/periodDelta;
        uint256 CurTimePeriod=timeStartPeriod+PeriodNum*periodDelta;
        return CurTimePeriod;
    }



    function CurrentRewardPool(uint256 time) internal view returns(uint256 sumReward)
    {
        if(time<timeStartPeriod)
            return 0;

        uint256 PeriodNum = (time-timeStartPeriod)/periodDelta;

        uint256 Percent;
        if(PeriodNum<countFirstsPeriods)
        {
            Percent=percentFirstsPeriods*(1+PeriodNum);
        }
        else
        {
            if(PeriodNum<countAllPeriods)
            {
                uint256 Percent1 = percentFirstsPeriods*countFirstsPeriods;
                uint256 Percent2 = (PERCENT100-Percent1)/(countAllPeriods-countFirstsPeriods);
                Percent = Percent1 + Percent2*(1+PeriodNum-countFirstsPeriods);
            }
            else
            {
                Percent=PERCENT100;//100%
            }
        }

        sumReward = allReward*Percent/PERCENT100;

        //console.log("Percent=%s, sumReward=%s",Percent,sumReward);
    }



    function _getReward(SSession memory Stake) internal view returns (uint256 )
    {
        if(poolStake!=0 && block.timestamp>Stake.Start + windowEnd)
        {
            uint256 time=block.timestamp;
            if(time>=Stake.End)
                time=Stake.End;

            uint256 Price=1e24*CurrentRewardPool(time-1)/poolStake;

            uint256 delta_time=time-Stake.Start;
            uint256 period=Stake.End-Stake.Start;
            uint256 percent=PERCENT100*delta_time/period;
            if(percent>PERCENT100)
                percent=PERCENT100;
            
            
            return Stake.Stake*Price*percent/PERCENT100/1e24;
        }
        else
        {
            return 0;
        }
    }


    //View
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
        returns (SInfoSession [] memory Arr)
    {
        uint256 length=MapSessionCounter[addr];
        if(startIndex<1)
            startIndex=1;
        if (startIndex <= length) 
        {
            if (startIndex + counts > length + 1) counts = length + 1 - startIndex;

            Arr = new SInfoSession[](counts);
            for (uint256 i = 0; i < counts; i++) 
            {
                SSession memory info=MapSession[addr][startIndex+i];
                Arr[i].info=info;
                Arr[i].reward=_getReward(info);
            }
        }
    }

}


