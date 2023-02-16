// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./MetableNFT.sol";


contract MetableSale is MetableNFT {
    ISmartToken public smartToken;

    ///@dev Storing info about sale market
    using EnumerableMap for EnumerableMap.UintToUintMap;
    EnumerableMap.UintToUintMap private EnumSalePrice;
    mapping(uint256 => address) private MapSaleOwner;

    struct SInfoSale {
        uint256 ID;
        uint256 Price;
        address Owner;
    }

    constructor(address addrToken) {
        smartToken = ISmartToken(addrToken);
    }

    /**
     * @dev Placement of a sale request
     * (internal use)
     * 
     * @param tokenId The token ID
     * @param price The rent price
     * @param addr The owner address
     */
    function _setSale(
        uint256 tokenId,
        uint256 price,
        address addr
    ) internal {
        require(EnumSalePrice.set(tokenId, price), "_setSale::Error set NFT to list");
        MapSaleOwner[tokenId] = addr;
    }


    /**
     * @dev Remove sale order
     * (internal use)
     * 
     * @param tokenId The token ID
     */
    function _removeSale(uint256 tokenId) internal {
        require(EnumSalePrice.remove(tokenId), "_setSale::Error remove NFT from list");
        MapSaleOwner[tokenId] = address(0);
    }

    /**
     * @dev Placement of a sale request
     * 
     * @param tokenId The token ID
     * @param price The rent price
     */
    function setSale(uint256 tokenId, uint256 price) external {
        require(price > 0, "setSale::Price is zero");

        //Get NFT from client
        _transfer(msg.sender, address(this), tokenId);

        //To sale
        _setSale(tokenId, price, msg.sender);
    }

    /**
     * @dev Remove sale order
     * 
     * @param tokenId The token ID
     */
    function removeSale(uint256 tokenId) external {
        require(MapSaleOwner[tokenId] == msg.sender, "removeSale::Sender not NFT owner");

        //Send NFT to client
        _transfer(address(this), msg.sender, tokenId);

        //Clear
        _removeSale(tokenId);
    }

    /**
     * @dev Execution of an order (purchase of NFT)
     * 
     * @param tokenId The token ID
     */
    function buyNFT(uint256 tokenId) external {
        uint256 Price = EnumSalePrice.get(tokenId);
        require(Price > 0, "buyNFT::Error NFT ID");

        //Get GameToken from client
        require(
            smartToken.SmartTransferTo(
                msg.sender,
                MapSaleOwner[tokenId],
                Price
            ),
            "buyNFT::Error transfer Token"
        );

        //Send NFT to client
        _transfer(address(this), msg.sender, tokenId);

        //Clear
        _removeSale(tokenId);
    }

    //View

    /**
     * @dev Retrieves number of sale orders
     * 
     * @return The number of items
     */
    function lengthSale() public view returns (uint256) {
        return EnumSalePrice.length();
    }

    /**
     * @dev Retrieves list of sale orders
     * 
     * @param startIndex The start list index
     * @param counts The number of items
     * @return Arr The array of items {SInfoSale}
     */
    function listSale(uint256 startIndex, uint256 counts)
        public
        view
        returns (SInfoSale[] memory Arr)
    {
        uint256 length = EnumSalePrice.length();

        if (startIndex < length) {
            if (startIndex + counts > length) counts = length - startIndex;

            uint256 ID;
            uint256 Price;
            Arr = new SInfoSale[](counts);
            for (uint256 i = 0; i < counts; i++) {
                (ID, Price) = EnumSalePrice.at(startIndex + i);
                Arr[i].ID = ID;
                Arr[i].Price = Price;
                Arr[i].Owner = MapSaleOwner[ID];
            }
        }
    }
}
