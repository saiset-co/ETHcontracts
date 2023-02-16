// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetableRentAsk.sol";


contract Metable is MetableRentAsk {
    constructor(address addrToken, address addrCourse)
        MetableRentAsk(addrToken, addrCourse)
    {}

     /**
     * @dev Mint new token to this smart addres
     * 
     * Emits a {Transfer} event.
     * 
     * @param Type The type of token
     * @param SubType The subtype of token
     * @param Metadata The metadata of token
     * @param MaxSlots The max childs NFT
     * @param MaxRents The max rent count
     * @param price The price for sale
     * @param count The count NFT for sale
     */
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

     /**
     * @dev Determines whether the rows are the same. Internal use only
     */
    function isEqString(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    //withdraw

    /**
     * @dev Transfer utility tokens from smart contract to address
     * 
     * Emits a {Transfer} event.
     * 
     * @param to The recipient's address
     * @param amount The amount of token
     */
    function transferToken(address to, uint256 amount) external onlyOwner {
        smartToken.SmartTransferTo(address(this), to, amount);
    }

    /**
    * @dev Withdraw the entire balance of utility tokens on a smart contract
    * 
    */
    function withdrawToken() external onlyOwner {
        smartToken.SmartTransferTo(
            address(this),
            msg.sender,
            smartToken.balanceOf(address(this))
        );
    }
}
