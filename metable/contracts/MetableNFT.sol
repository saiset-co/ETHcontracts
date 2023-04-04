// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PrimaryNFT.sol";

///@dev Short version of the NFT standard interface
interface INFTToken {

    function ownerOf(uint256 tokenId) external returns (address);
}

///@dev A token interface that can be managed by a smart contract
interface ISmartToken {
    function SmartTransferTo(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}


contract MetableNFT is PrimaryNFT {

    
    ///@dev Storing main data for NFT
    struct SItem {
        uint48 ParentLink;
        uint16 MaxRents;
        uint8  Rentable;
        uint8  School;
        uint16 MaxSlots;
        uint256[] Slots;
        string Type;
        string SubType;
        string Metadata;
    }
    mapping(uint256 => SItem) internal mapItem;


    constructor() PrimaryNFT("Metable NFT", "MTB-NFT") {}

    /**
     * @dev Hierarchical binding of NFT tokens (internal use)
     * 
     * @param tokenId The child token
     * @param parentId The parent token
     */
    function _linkToNFT(uint256 tokenId, uint256 parentId) internal {

        SItem storage data = mapItem[tokenId];

        require(
            data.ParentLink == 0,
            "_linkToNFT::The linking to the slot has already been completed"
        );

        SItem storage parent = mapItem[parentId];
        
        
        require(parent.MaxSlots > parent.Slots.length, "No slots available");

        parent.Slots.push(tokenId);
        data.ParentLink = uint48(parentId);
    }

    /**
     * @dev Hierarchical binding of NFT tokens
     * 
     * @param tokenId The child token
     * @param parentId The parent token
     */
    function linkToNFT(uint256 tokenId, uint256 parentId) external onlyNFTOwner(tokenId) {
        require(ownerOf(parentId) == msg.sender, "linkToNFT::Error Parent owner");

        _linkToNFT(tokenId, parentId);
    }

    /**
     * @dev Set metadata to token
     * 
     * @param tokenId The token id
     * @param Metadata The string type metadata of token
     */
    function setMetadata(uint256 tokenId, string memory Metadata)
        public
        onlyOwner
    {
        require(ownerOf(tokenId) != address(0), "setMetadata::Invalid token ID");

        mapItem[tokenId].Metadata = Metadata;
    }
/*
    function setRenter(uint256 tokenId, address addr) public onlySmart {
        require(ownerOf(tokenId) != address(0), "Invalid token ID");

        mapItem[tokenId].Renter = addr;
    }
*/

    //View

    /**
     * @dev Retrieves value of token data
     * 
     * @param tokenId The token id
     * @return The token data {SItem}
     */
    function getInfo(uint256 tokenId) public view returns (SItem memory) {
        require(ownerOf(tokenId) != address(0), "getInfo::Invalid token ID");
        return mapItem[tokenId];
    }

    /**
     * @dev Retrieves the number of free slots (for hierarchical linking)
     * 
     * @param tokenId The token id
     * @return The number of free slots
     */
    function getFreeLinkedSlots(uint256 tokenId) public view returns (uint256) {
        SItem memory data = getInfo(tokenId);
        return data.MaxSlots - data.Slots.length;
    }

    /**
     * @dev Retrieves linked slots
     * 
     * @param tokenId The token id
     * @return The linked slots
     */
    function getLinkedToNFTs(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.Slots;
    }


    /**
     * @dev Retrieves NFT type
     * 
     * @param tokenId The token id
     * @return The type (string)
     */
    function getNFTType(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.Type;
    }
    /**
     * @dev Retrieves NFT subtype
     * 
     * @param tokenId The token id
     * @return The subtype (string)
     */
    function getNFTSubType(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.SubType;
    }

    /**
     * @dev Retrieves value of token metadata
     * 
     * @param tokenId The token id
     * @return The metadata of token
     */
    function getMetadata(uint256 tokenId) public view returns (string memory) {
        SItem memory data = getInfo(tokenId);
        return data.Metadata;
    }

}
