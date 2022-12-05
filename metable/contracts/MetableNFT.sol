// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./SmartOnly.sol";
import "./PrimaryNFT.sol";

interface INFTToken {

    function ownerOf(uint256 tokenId) external returns (address);
}
interface ISmartToken {
    function SmartTransferTo(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}


contract MetableNFT is PrimaryNFT {

    //uint8 constant GENERATE_RENT_LEVEL = 3;

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

    function linkToNFT(uint256 tokenId, uint256 parentId) external onlyNFTOwner(tokenId) {
        require(ownerOf(parentId) == msg.sender, "linkToNFT::Error Parent owner");

        _linkToNFT(tokenId, parentId);
    }

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

    function getInfo(uint256 tokenId) public view returns (SItem memory) {
        require(ownerOf(tokenId) != address(0), "getInfo::Invalid token ID");
        return mapItem[tokenId];
    }

    function getFreeLinkedSlots(uint256 tokenId) public view returns (uint256) {
        SItem memory data = getInfo(tokenId);
        return data.MaxSlots - data.Slots.length;
    }

    function getLinkedToNFTs(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.Slots;
    }


    function getNFTType(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.Type;
    }
    function getNFTSubType(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        SItem memory data = getInfo(tokenId);
        return data.SubType;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        SItem memory data = getInfo(tokenId);
        return data.Metadata;
    }

}
