// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./MetableRentBid.sol";


contract MetableRentAsk is  MetableRentBid {

    struct SMarketRentAsk {
        uint48 ID;
        uint48 Period;
        address Owner;
        uint256 Price;
    }

    struct SInfoRentAsk {
        bytes32 Key;
        uint48 ID;
        uint48 Period;
        address Owner;
        uint256 Price;
    }


    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;

    EnumerableMap.Bytes32ToBytes32Map private EnumRentAsk;
    mapping(bytes32 => SMarketRentAsk) private MarketRentAsk;

    constructor(address addrToken, address addrCourse) MetableRentBid(addrToken,addrCourse) {}

    //Ask market


    function setRentAsk(
        uint256 tokenId,
        uint256 price,
        uint256 period
    ) external  {
        require(tokenId > 0, "setRentAsk::tokenId is zero");
        require(price > 0, "setRentAsk::Price is zero");
        require(period > 0, "setRentAsk::Period is zero");


        SItem memory item = getInfo(tokenId);
        require(item.School == 0, "setRentAsk::Require not school NFT");

        bytes32 key=keccak256(abi.encodePacked(msg.sender,tokenId));

        EnumRentAsk.set(key, 0);
        MarketRentAsk[key] = SMarketRentAsk(uint48(tokenId),uint48(period), msg.sender, price);
    }

    function removeRentAsk(uint256 tokenId) external {
        bytes32 key=keccak256(abi.encodePacked(msg.sender,tokenId));
        require(
            EnumRentAsk.remove(key),
            "removeRentAsk::Error remove NFT from list"
        );
        delete MarketRentAsk[key];
    }

    function approveRentAsk(bytes32 key, uint256 index) external {

        SMarketRentAsk memory data = MarketRentAsk[key];
        uint256 tokenId= uint256(data.ID);

        require(
            ownerOf(tokenId) == msg.sender,
            "approveRentAsk::Sender not owner NFT"
        );


        
        //Get GameToken from client
        require(
            smartToken.SmartTransferTo(data.Owner,msg.sender, data.Price),
            "_buyRentBid::Error transfer Token"
        );

        //Set user for NFT
        _setRent(
            tokenId,
            index,
            data.Owner,
            uint64(uint64(block.timestamp) + uint64(data.Period))
        );


        //Clear
        EnumRentAsk.remove(key);
        delete MarketRentAsk[key];
    }


    //View

    function lengthRentAsk() public view returns (uint256) {
        return EnumRentAsk.length();
    }

    function listRentAsk(uint256 startIndex, uint256 counts)
        public
        view
        returns (SInfoRentAsk[] memory Arr)
    {
        uint256 length = EnumRentAsk.length();

        if (startIndex < length) {
            if (startIndex + counts > length) counts = length - startIndex;

            bytes32 key;
            Arr = new SInfoRentAsk[](counts);
            for (uint256 i = 0; i < counts; i++) {
                (key, ) = EnumRentAsk.at(startIndex + i);
                SMarketRentAsk memory data = MarketRentAsk[key];

                Arr[i].Key = key;
                Arr[i].ID = data.ID;
                Arr[i].Period = data.Period;
                Arr[i].Owner = data.Owner;
                Arr[i].Price = data.Price;
            }
        }
    }

}
