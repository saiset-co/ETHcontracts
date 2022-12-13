// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



interface IRouter{
    function getAmountsOut(uint amountIn, address[] memory path)  view  external  returns (uint[] memory amounts);
}




contract UndeadsStakingUGOLD is Ownable
{
    using SafeERC20 for IERC20;


    uint256 constant public PERCENT100=1e9;

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
    }
    struct SInfoSession{
        SSession info;
        uint256 reward;
    }

    //      user    -> idSession -> {SSession}
    mapping(address => mapping(uint256 => SSession)) private MapSession;
    mapping(address => uint256) private MapSessionCounter;
    
    mapping(address => uint256) private MapWallet;



    IERC20 smartGOLD;
    IRouter smartAMM;
    address[] public pathAMM;
    address saleAddress;


    constructor(address addrUDS,address addrUGOLD, address addrAMM, address addrSale)
    {
        smartGOLD=IERC20(addrUGOLD);
        smartAMM=IRouter(addrAMM);

        pathAMM=[addrUGOLD,addrUDS];
        saleAddress=addrSale;
        

   
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

    function stake(uint256 _amount,uint256 _periodDay)  external
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
        smartGOLD.safeTransferFrom(msg.sender, address(this), _amount);

        uint[] memory amounts = smartAMM.getAmountsOut(_amount, pathAMM);
        uint256 Amount=amounts[0];



  
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

        poolStake+=amountStake;
    }

 

    function unstake(uint32 sessionId)  external
    {
        SSession memory Stake=MapSession[msg.sender][sessionId];
        require(Stake.End>0,"Error sessionId");
        require(block.timestamp > Stake.End, "Error unstaking time");

        
        //transfer coins staking body to client
        smartGOLD.safeTransfer(msg.sender, Stake.Amount);

        //reward
        MapWallet[msg.sender]+=_getReward(Stake);

        delete MapSession[msg.sender][sessionId];
    }


   function CurrentRewardPool(uint256 time) public view returns(uint256)
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

        return allReward*Percent/PERCENT100;
    }



    function _getReward(SSession memory Stake) private view returns (uint256 )
    {
        if(poolStake!=0 && block.timestamp>Stake.Start + windowEnd)
        {
            uint256 time=block.timestamp;
            if(time>=Stake.End)
                time=Stake.End-1;

            uint256 Price=1e18*CurrentRewardPool(time)/poolStake;

            uint256 delta_time=time-Stake.Start;
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


    function burn(address addr, uint256 amount) public
    {
        require(msg.sender==saleAddress,"Error sale address");
        require(MapWallet[addr]>=amount,"Error balance");

        MapWallet[addr] -= amount;
    }





    //View
    function balanceOf(address addr)
        public
        view
        returns (uint256)
    {
        return MapWallet[addr];
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


