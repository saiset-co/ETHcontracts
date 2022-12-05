// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetableRentAsk.sol";


contract Metable is MetableRentAsk {
    constructor(address addrToken, address addrCourse)
        MetableRentAsk(addrToken, addrCourse)
    {}

    function Mint(
        string memory Type,
        string memory SubType,
        string memory Metadata,
        uint16 MaxSlots,
        uint16 MaxRents,
        uint256 price,
        uint256 count
    ) public onlyOwner {

        address to = address(this);
        for(uint256 i=0;i<count;i++)
        {
            uint256 tokenId = _NewToken(to);

            SItem memory data;
            data.Type = Type;
            data.SubType = SubType;
            data.Metadata = Metadata;
            data.MaxSlots = MaxSlots;

            if(isEqString(SubType,"school"))
                data.School = 1;

            mapItem[tokenId] = data;

            MapRents[tokenId].MaxRents=MaxRents;
            
            if (price > 0) _setSale(tokenId, price, address(this));
        }
    }



    function isEqString(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    //withdraw

    function transferToken(address to, uint256 amount) external onlyOwner {
        smartToken.SmartTransferTo(address(this), to, amount);
    }

    function withdrawToken() external onlyOwner {
        smartToken.SmartTransferTo(
            address(this),
            msg.sender,
            smartToken.balanceOf(address(this))
        );
    }
}
