// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmartOnly.sol";
import "./PrimaryNFT.sol";
//import "./MetableNFT.sol";

contract CoursesNFT is PrimaryNFT, SmartOnly {
    mapping(uint256 => string) internal mapMetadata;

    //MetableNFT smartNFT;
    constructor() PrimaryNFT("Courses NFT", "CRS") {
       
    }


    function Mint(string memory Metadata) public {

        //address to = address(this);
        uint256 tokenId = _NewToken(msg.sender);

        mapMetadata[tokenId] = Metadata;
    }


    function SmartTransferTo(address from, address to, uint256 tokenId)
        external
        onlySmart
        returns (bool)
    {
        _transfer(from, to, tokenId);

        return true;
    }

    function setMetadata(uint256 tokenId, string memory Metadata)
        public
        onlyNFTOwner(tokenId)
    {
        require(ownerOf(tokenId) != address(0), "Invalid token ID");

        mapMetadata[tokenId] = Metadata;
    }

    //View

    function getMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "Invalid token ID");
        return mapMetadata[tokenId];
    }
}
