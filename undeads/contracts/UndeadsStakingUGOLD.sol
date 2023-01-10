// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



interface IRouter{
    function getAmountsOut(uint amountIn, address[] memory path)  view  external  returns (uint[] memory amounts);
}

interface UndeadNFT is IERC721 {
    //function craft(address owner_, uint256 subClass) external returns(uint256);

    function craft(
            address owner_,
            uint256 class_,
            uint256 subclass_,
            uint256 location_,
            uint16[10] memory props_,
            uint8 slots_,
            uint256 count_,
            string memory image_,
            string memory dynamic_
        ) external returns (uint256);
}




contract UndeadsStakingUGOLD is Ownable
{
    using SafeERC20 for IERC20;

    event Stake(address indexed owner, uint256 idSession, uint256 value, uint256 idNFT, uint256 periodDays, uint256 Reward);
    event UnStake(address indexed owner, uint256 idSession, uint256 value, uint256 idNFT, uint256 periodDays);
  
    event Price(uint256 class, uint256 price, uint256 subClass);
    event PriceRemove(uint256 class, uint256 price);
    
    event NFTTable(uint256 class, uint256 subClass, SNFTResource data);
    event NFTTableRemove(uint256 class, uint256 subClass);

    



    struct SSession
    {
        uint48 Start;    //timestamp
        uint48 End;      //timestamp
        uint128 Body;    //68+60 bits
        uint256 idNFT;
    }

    uint256 public PeriodOneDay;//delta sec
    uint256 public poolReward;
    uint256 public poolStake;

    //        user  -> idSession -> {SSession}
    mapping(address => mapping(uint256 => SSession)) internal MapSession;
    mapping(address => uint256) internal MapSessionCounter;

    //        class -> price  -> subclass
    mapping(uint256 => mapping(uint256 => uint256)) internal MapPriceNFT;


    struct SNFTResource
    {
        uint256 location;
        uint16[10] props;
        uint8 slots;
        uint256 count;
        string image;
        string dynamic;
    }


    //       class -> subclass  -> {SNFTResource}
    mapping(uint256 => mapping(uint256 => SNFTResource)) internal MapNFTResource;

    UndeadNFT public smartNFT;
    IERC20 public smartUDS;
    IERC20 public smartGOLD;
    IRouter public smartAMM;
    address[] public pathAMM;

    uint48 public minStakePeriod;
    uint48 public maxStakePeriod;


    constructor(address _addrUDS,address _addrUGOLD, address _addrNFT, address _addrAMM, uint256 _periodOneDay)
    {
        smartUDS=IERC20(_addrUDS);
        smartGOLD=IERC20(_addrUGOLD);
        smartAMM=IRouter(_addrAMM);
        smartNFT=UndeadNFT(_addrNFT);

        pathAMM=[_addrUGOLD,_addrUDS];

        require(_periodOneDay>0,"Error, zero periodOneDay");
        PeriodOneDay=_periodOneDay;

        minStakePeriod=30;
        maxStakePeriod=365;
    }
    



    function stake(uint256 _amount,uint256 _periodDay,uint256 _class, uint256 _price)  external
    {
        require(_amount>0,"Error, zero amount");
        require(_periodDay>0,"Error, zero periodDay");
        require(_periodDay>=minStakePeriod && _periodDay<=maxStakePeriod,"Error periodDay");


        //transfer coins from client
        smartGOLD.safeTransferFrom(msg.sender, address(this), _amount);

        uint[] memory amounts = smartAMM.getAmountsOut(_amount, pathAMM);
        uint256 AmountUDS=amounts[1];

        uint256 amountReward=AmountUDS*6/10*_periodDay/365;
        require(poolReward >= amountReward,"Not enough reward pool");

        uint256 subClass=MapPriceNFT[_class][_price];
        require(subClass>0 && amountReward>=_price,"Error NFT price");
        subClass--;
        

        //uint256 idNFT=smartNFT.craft(address(this), subClass);
        SNFTResource memory data = MapNFTResource[_class][subClass];
        uint256 idNFT=smartNFT.craft(address(this), _class, subClass,
                                    data.location,
                                    data.props,
                                    data.slots,
                                    data.count,
                                    data.image,
                                    data.dynamic);


        MapSessionCounter[msg.sender]++;
        uint256 id=MapSessionCounter[msg.sender];
        SSession storage Session=MapSession[msg.sender][id];

        Session.Start = uint48(block.timestamp);
        Session.End = uint48(block.timestamp+_periodDay*PeriodOneDay);
        Session.Body = uint128(_amount);
        Session.idNFT = idNFT;



        poolReward-=amountReward;
        poolStake+=amountReward;

        emit Stake(msg.sender, id, Session.Body, idNFT, _periodDay, amountReward);
    }


 

    function unstake(uint32 _sessionId)  external
    {
        SSession memory Session=MapSession[msg.sender][_sessionId];
        require(Session.End>0,"Error sessionId");
        require(block.timestamp > Session.End, "Error unstaking time");

        //transfer coins staking body to client
        smartGOLD.safeTransfer(msg.sender, Session.Body);

        //transfer NFT to client
        smartNFT.transferFrom(address(this),msg.sender,Session.idNFT);
       
        emit UnStake(msg.sender, _sessionId, Session.Body, Session.idNFT, (Session.End-Session.Start)/PeriodOneDay);
        delete MapSession[msg.sender][_sessionId];
    }


    //admin mode
    function setStakePeriod(uint48 _min, uint48 _max)  external onlyOwner
    {
        minStakePeriod=_min;
        maxStakePeriod=_max;
    }


    function setPrice(uint256 _class, uint256 _price, uint256 _subClass)  external onlyOwner
    {
        require(_price>0,"Error, zero price");
        MapPriceNFT[_class][_price]= 1 + _subClass;

        emit Price(_class, _price, _subClass);
    }




    function removePrice(uint256 _class, uint256 _price)  external onlyOwner
    {
        delete MapPriceNFT[_class][_price];
        emit PriceRemove(_class, _price);
    }




    

    function getSubClass(uint256 _class, uint256 _price) external view returns(int256)
    {
        int256 subClass = int256(MapPriceNFT[_class][_price]);
        return subClass - 1;
    }





 
  
    //pools
    function addReward(uint256 _amount)  external onlyOwner
    {
        //transfer coins from owner
        smartUDS.safeTransferFrom(msg.sender, address(this), _amount);

        poolReward+=_amount;
    }

    function withdrawReward(uint256 _amount)  external onlyOwner
    {
        require(poolReward >= _amount,"Not enough reward pool");

        //transfer coins to owner
        smartUDS.safeTransfer(msg.sender, _amount);

        poolReward-=_amount;
    }

    function withdrawStake(uint256 _amount)  external onlyOwner
    {
        require(poolStake >= _amount,"Not enough stake pool");

        //transfer coins to owner
        smartUDS.safeTransfer(msg.sender, _amount);

        poolStake-=_amount;
    }



    //View
    function lengthSessions(address _addr)
        public
        view
        returns (uint256)
    {
        return MapSessionCounter[_addr];
    }

    function listSessions(address _addr,uint256 _startIndex,uint256 _counts)
        public
        view
        returns (SSession [] memory Arr)
    {
        uint256 length=MapSessionCounter[_addr];
        if(_startIndex<1)
            _startIndex=1;
        if (_startIndex <= length) 
        {
            if (_startIndex + _counts > length + 1) _counts = length + 1 - _startIndex;

            Arr = new SSession[](_counts);
            for (uint256 i = 0; i < _counts; i++) 
            {
                Arr[i]=MapSession[_addr][_startIndex+i];
            }
        }
    }






    //NFT Resource Table
    function setNFTRaw(uint256 _class, uint256 _subClass, SNFTResource memory data)  external onlyOwner
    {
        MapNFTResource[_class][_subClass]=data;
        emit NFTTable(_class, _subClass, data);
    }




    function removeNFTRaw(uint256 _class, uint256 _subClass)  external onlyOwner
    {
        delete MapNFTResource[_class][_subClass];
        emit NFTTableRemove(_class, _subClass);
    }

    function getNFTRaw(uint256 _class, uint256 _subClass)  external view returns (SNFTResource memory)
    {
        return MapNFTResource[_class][_subClass];
    }
    

}



