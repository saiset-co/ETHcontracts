// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

contract UndeadsStaking is Ownable
{
    event Stake(address indexed owner, uint256 idSession, uint256 value, uint256 idNFT, uint256 periodDays, uint256 unitRewards);
    event UnStake(address indexed owner, uint256 idSession, uint256 value, uint256 idNFT, uint256 periodDays);
    event Reward(address indexed owner, uint256 idSession, uint256 value, uint256 idNFT, uint256 periodDays);



    uint256 constant internal PERCENT100=1e18;

    uint48 public timeStartContract;//time stamp
    uint48 public timeEndContract;//time stamp
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
        setup(5e25, uint48(block.timestamp), 86400, 30, 1440,60,1333333);
    }
    



    //_percentFirstsPeriods 100% = 1e9
    function setup(uint256 _amount, uint48 _startPeriods, uint32 _periodDelta, uint32 _windowEnd, uint32 _countAllPeriods, uint32 _countFirstsPeriods,uint32 _percentFirstsPeriods)  public onlyOwner
    {
        require(_amount>0,"Error, zero amount");
        require(_startPeriods>0,"Error, zero startPeriods");
        require(_periodDelta>0,"Error, zero periodDelta");
        require(_countAllPeriods>0,"Error, zero countAllPeriods");
        
        allReward = _amount;
        timeStartContract=_startPeriods;
        timeEndContract=_startPeriods+_periodDelta*_countAllPeriods;
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

    function _stake(uint256 _amountBody,uint256 _amountEffect, uint256 _periodDay, uint256 _idNFT)  internal
    {
        uint256 CurTimePeriod=_currentPeriodTime();

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

        uint256 EndTimeStake=CurTimePeriod + _periodDay * 86400;
        require(EndTimeStake<=timeEndContract,"The staking period exceeds the lifetime of the smart contract");

        //uint256 amountStake=_amountEffect*PercentYear/100/360;
        uint256 amountStake=_amountEffect*_periodDay*PercentYear/100/360;


        MapSessionCounter[msg.sender]++;
        uint256 id=MapSessionCounter[msg.sender];
        SSession storage Session=MapSession[msg.sender][id];

        Session.Start = uint48(CurTimePeriod);
        Session.End = uint48(EndTimeStake);
        Session.Body = uint128(_amountBody);
        Session.Stake =  uint128(amountStake);
        Session.Withdraw = 0;
        Session.idNFT = _idNFT;

        poolStake+=Session.Stake;

        emit Stake(msg.sender, id, Session.Body, _idNFT, _periodDay, Session.Stake);

    }


    function _unstake(SSession memory Session, uint32 sessionId) internal
    {
        /*
        if(poolStake>Session.Stake)
            poolStake -= Session.Stake;
        else
            poolStake = 0;
            //*/
            
        emit UnStake(msg.sender, sessionId, Session.Body, Session.idNFT, (Session.End-Session.Start)/86400);

        delete MapSession[msg.sender][sessionId];
    }



    function _currentPeriodTime() private view returns(uint256)
    {
        require(block.timestamp > timeStartContract, "Error start staking time");
        uint256 PeriodNum = (block.timestamp-timeStartContract)/periodDelta;
        uint256 CurTimePeriod=timeStartContract+PeriodNum*periodDelta;
        return CurTimePeriod;
    }



    function _currentRewardPool(uint256 time) private view returns(uint256 sumReward)
    {
        if(time<timeStartContract)
            return 0;

        uint256 PeriodNum = (time-timeStartContract)/periodDelta;

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



    function _getReward(SSession memory Session) internal view returns (uint256 )
    {
        if(poolStake!=0 && block.timestamp>Session.Start + windowEnd)
        {
            uint256 time=block.timestamp;
            if(time>=Session.End)
                time=Session.End;

            uint256 Price=1e24*_currentRewardPool(time-1)/poolStake;

            uint256 delta_time=time-Session.Start;
            uint256 period=Session.End-Session.Start;
            uint256 percent=PERCENT100*delta_time/period;
            if(percent>PERCENT100)
                percent=PERCENT100;
            
            
            return Session.Stake*Price*percent/PERCENT100/1e24;
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


