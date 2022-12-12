// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface UndeadNFT is IERC721 {
    function getPrice(uint256 id) external returns(uint256);
}

interface IRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


contract UndeadsStakingUDS is Ownable
{
    using SafeERC20 for IERC20;


    uint256 constant public PERCENT100=1e6;

    uint48 public timeStartPeriod;//time stamp
    uint32 public periodDelta;//delta sec
    uint32 public windowEnd;  //delta sec

    uint32 public countAllPeriods;   //all periods
    uint32 public countFirstsPeriods;//count boost staking period
    uint32 public percentFirstsPeriods;

    uint256 public allReward;
    uint256 public poolStake;


    struct SSession{
        uint48 Start; //timestamp
        uint48 End;   //timestamp
        uint128 Amount;  //68+60 bits
        uint128 Stake;   //68+60 bits
        uint128 Withdraw;//68+60 bits
        uint256 idNFT;
    }
    struct SInfoSession{
        SSession info;
        uint256 reward;
    }

    //      user    -> idSession -> {SSession}
    mapping(address => mapping(uint256 => SSession)) private MapSession;
    mapping(address => uint256) private MapSessionCounter;
    



    IERC20 smartUDS;
    UndeadNFT smartNFT;
    IRouter smartAMM;
    address[] public pathAMM;


    constructor(address addrUDS,address addrUGOLD, address addrNFT, address addrAMM)
    {
        smartUDS=IERC20(addrUDS);
        smartNFT=UndeadNFT(addrNFT);
        smartAMM=IRouter(addrAMM);

        pathAMM=[addrUDS,addrUGOLD];



   
        periodDelta=86400;
        countFirstsPeriods=60;
        percentFirstsPeriods=uint32(PERCENT100*10/30/100);

        windowEnd=30;
    }



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
        percentFirstsPeriods=_percentFirstsPeriods;
    }

    function setPeriod(uint32 _periodDelta)  external onlyOwner
    {
        require(_periodDelta>0,"Error, zero periodDelta");
        periodDelta=_periodDelta;
    }


    function _GetCurPeriodTime() private view returns(uint256)
    {
        require(block.timestamp > timeStartPeriod, "Error start staking time");
        uint256 PeriodNum = (block.timestamp-timeStartPeriod)/periodDelta;
        uint256 CurTimePeriod=timeStartPeriod+PeriodNum*periodDelta;
        return CurTimePeriod;
    }

    function stake(uint256 _amount,uint256 _periodDay, uint256 idNFT)  external
    {

        uint256 CurTimePeriod=_GetCurPeriodTime();

        require(_amount>0,"Error, zero amount");
        //require(_periodDay>0,"Error, zero periodDay");
        //require(block.timestamp < CurTimePeriod + windowEnd, "Error end staking window");
        if(block.timestamp >= CurTimePeriod + windowEnd)
        {
            CurTimePeriod += periodDelta;
        }


        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 Amount=_amount;
        if(idNFT>0)
        {
            //transfer NFT from client
            smartNFT.safeTransferFrom(msg.sender,address(this),idNFT);

            Amount += smartNFT.getPrice(idNFT);
        }



        uint256 amountStake;
        if(_periodDay==30)
            amountStake=Amount*1;
        else
        if(_periodDay==60)
            amountStake=Amount*5;
        else
        if(_periodDay==90)
            amountStake=Amount*10;
        if(_periodDay==120)
            amountStake=Amount*24;
        else
        if(_periodDay==180)
            amountStake=Amount*40;
        else
        if(_periodDay==365)
            amountStake=Amount*75;
        else
        if(_periodDay==730)
            amountStake=Amount*170;
        else {
            revert("Error _periodDay params");
        }

        amountStake=amountStake*_periodDay/100/360;


        MapSessionCounter[msg.sender]++;
        uint256 id=MapSessionCounter[msg.sender];
        SSession storage Stake=MapSession[msg.sender][id];

        Stake.Start = uint48(CurTimePeriod);
        Stake.End = uint48(CurTimePeriod + _periodDay * 86400);
        Stake.Amount = uint128(_amount);
        Stake.Stake =  uint128(amountStake);
        Stake.Withdraw = 0;

        poolStake+=amountStake;
    }

    function reward(uint32 sessionId)  external
    {
        _reward(sessionId,false);
    }

    function _reward(uint32 sessionId, bool bSilient)  private
    {
        SSession storage Stake=MapSession[msg.sender][sessionId];
        
        //uint256 CurTimePeriod=_GetCurPeriodTime();
        require(block.timestamp > Stake.Start + windowEnd, "Error reward time");



        //calc reward
        uint256 amount = _getReward(Stake);
        if(Stake.Withdraw>=amount)
        {
            if(!bSilient)
                revert("There is nothing to withdraw reward");
            return;
        }


        uint256 delta = amount-Stake.Withdraw;
        if(Stake.idNFT>0)
        {
            smartUDS.safeApprove(address(smartAMM),delta);
            smartAMM.swapExactTokensForTokens(delta, 0, pathAMM, msg.sender,block.timestamp);
        }
        else {
            //transfer coins to client
            smartUDS.safeTransfer(msg.sender, delta);
        }



        Stake.Withdraw += uint128(delta);
    }

    


    function unstake(uint32 sessionId)  external
    {
        SSession memory Stake=MapSession[msg.sender][sessionId];
        require(Stake.End>0,"Error sessionId");
        require(block.timestamp > Stake.End, "Error unstaking time");

        //refund reward
        _reward(sessionId,true);

        uint256 amount=Stake.Amount;

        if(amount>0)
        {
            //transfer coins staking body to client
            smartUDS.safeTransfer(msg.sender, amount);
        }

        if(Stake.idNFT>0)
        {
            //transfer NFT staking body to client
            smartNFT.safeTransferFrom(address(this),msg.sender,Stake.idNFT);
        }


        delete MapSession[msg.sender][sessionId];
    }


    function CurrentRewardPool() public view returns(uint256)
    {
        if(block.timestamp<timeStartPeriod)
            return 0;

        uint256 PeriodNum = (block.timestamp-timeStartPeriod)/periodDelta;
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
                uint256 Percent2 = (PERCENT100-Percent1)/countAllPeriods;
                Percent = Percent1 + Percent2*(1+PeriodNum-percentFirstsPeriods);
            }
            else
            {
                Percent=PERCENT100;//100%
            }
        }
        

        return allReward*Percent/PERCENT100;
    }



    function _getReward(SSession memory Stake) private view returns (uint256 )
    {
        if(poolStake!=0 && block.timestamp>Stake.Start)
        {
            uint256 Price=1e18*CurrentRewardPool()/poolStake;

            uint256 delta_time=block.timestamp-Stake.Start;
            uint256 period=Stake.End-Stake.Start;
            uint256 percent=PERCENT100*delta_time/period;
            if(percent>PERCENT100)
                percent=PERCENT100;
            
            
            return Stake.Stake*Price*percent/PERCENT100/1e18;
        }
        else
        {
            return 0;
        }
    }







    //View
    /*
    function balanceOf(address addr,uint32 sessionId)
        public
        view
        returns (uint256)
    {
        SSession memory Stake=MapSession[addr][sessionId];
        return Stake.Amount;
    }
   

    function rewardOf(address addr,uint32 sessionId)
        public
        view
        returns (uint256)
    {
        SSession memory Stake=MapSession[addr][sessionId];

        return _getReward(Stake);
    }
    */

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


