

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./MetableRent.sol";

contract MetableRentBid is MetableRent {

    struct SMarketRentBid {
        uint48 Period;
        address Owner;
        uint256 Price;
    }

    struct SInfoRentBid {
        uint48 ID;
        uint48 Period;
        address Owner;
        uint256 Price;
        uint256 Count;
    }

    using EnumerableMap for EnumerableMap.UintToUintMap;

    EnumerableMap.UintToUintMap private EnumRentBid;
    mapping(uint256 => SMarketRentBid) private MarketRentBid;

    constructor(address addrToken, address addrCourse) MetableRent(addrToken,addrCourse) {}


    //Bid market

    function _setRentBid(
        uint256 tokenId,
        uint256 price,
        uint256 period,
        uint256 count
    ) internal {
        EnumRentBid.set(tokenId, count);
        MarketRentBid[tokenId] = SMarketRentBid(uint48(period), msg.sender, price);
    }

    function _removeRentBid(uint256 tokenId) internal {
        require(
            EnumRentBid.remove(tokenId),
            "_removeRentBid::Error remove NFT from list"
        );
        delete MarketRentBid[tokenId];
    }

    function setRentBid(
        uint256 tokenId,
        uint256 price,
        uint256 period,
        uint256 count
    ) external onlyNFTOwner(tokenId) {
        require(price > 0, "setRentBid::Price is zero");
        require(period > 0, "setRentBid::Period is zero");

        SRentItem memory info = MapRents[tokenId];
        require(info.MaxRents >= count,"setRentBid::Error, count < MaxRents");

        //Set
        _setRentBid(tokenId, price, period,count);
    }

    function removeRentBid(uint256 tokenId) external onlyNFTOwner(tokenId) {
        SMarketRentBid memory data = MarketRentBid[tokenId];
        require(
            data.Owner == msg.sender,
            "removeRentBid::Sender not NFT owner"
        );

        //Clear
        _removeRentBid(tokenId);
    }

    function _buyRentBid(
        uint256 tokenId,
        uint256 index,
        uint256 courseId
    ) internal {
        uint256 count=EnumRentBid.get(tokenId);
        require(count>0, "_buyRentBid::Not found ID in list");
        SMarketRentBid memory data = MarketRentBid[tokenId];
        

        SItem memory item = getInfo(tokenId);

        if (courseId > 0)
            require(item.School == 1, "_buyRentBid::Require school NFT");
        else require(item.School == 0, "_buyRentBid::Require not school NFT");

        //Get GameToken from client
        require(
            smartToken.SmartTransferTo(msg.sender, data.Owner, data.Price),
            "_buyRentBid::Error transfer Token"
        );

        //Set user for NFT
        _setRent(
            tokenId,
            index,
            msg.sender,
            uint64(uint64(block.timestamp) + uint64(data.Period))
        );

        //Clear
        count--;
        if(count==0)
            _removeRentBid(tokenId);
        else
            EnumRentBid.set(tokenId, count);
    }

    function buyRentBid(uint256 tokenId, uint256 index) external {
        _buyRentBid(tokenId, index, 0);
    }

    function buyRentSchoolBid(
        uint256 tokenId,
        uint256 courseId,
        uint256 index
    ) external {
        require(courseId > 0, "buyRentSchoolBid::Error, courseId is zero");

        require(
            smartCourse.ownerOf(courseId) == msg.sender,
            "buyRentSchoolBid::Sender not owner Course ID"
        );
        _buyRentBid(tokenId, index, courseId);
    }


    //View

    function lengthRentBid() public view returns (uint256) {
        return EnumRentBid.length();
    }

    function listRentBid(uint256 startIndex, uint256 counts)
        public
        view
        returns (SInfoRentBid[] memory Arr)
    {
        uint256 length = EnumRentBid.length();

        if (startIndex < length) {
            if (startIndex + counts > length) counts = length - startIndex;

            uint256 ID;
            uint256 Count;
            Arr = new SInfoRentBid[](counts);
            for (uint256 i = 0; i < counts; i++) {
                (ID, Count) = EnumRentBid.at(startIndex + i);
                SMarketRentBid memory data = MarketRentBid[ID];

                Arr[i].ID = uint48(ID);
                Arr[i].Period = data.Period;
                Arr[i].Owner = data.Owner;
                Arr[i].Price = data.Price;
                Arr[i].Count = Count;
            }
        }
    }
}
