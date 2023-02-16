// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmartOnly.sol";
import "./PrimaryNFT.sol";
//import "./MetableNFT.sol";

contract CoursesNFT is PrimaryNFT, SmartOnly {
    ///@dev Storage info about NFT metadata
    mapping(uint256 => string) internal mapMetadata;

    //MetableNFT smartNFT;
    constructor() PrimaryNFT("Courses NFT", "CRS") {
       
    }


    /**
     * @dev Mint new NFT to sender
     * 
     * Emits a {Transfer} event.
     * 
     * @param Metadata The string type metadata of token
     */
    function Mint(string memory Metadata) public {

        
        uint256 tokenId = _NewToken(msg.sender);

        mapMetadata[tokenId] = Metadata;
    }


    /**
     * @dev Token transfer, called from other smart contracts
     * 
     * @param from The sender's address
     * @param to The recipient's address
     * @param tokenId The token id
     */
    function SmartTransferTo(address from, address to, uint256 tokenId)
        external
        onlySmart
        returns (bool)
    {
        _transfer(from, to, tokenId);

        return true;
    }

    /**
     * @dev Set metadata to token
     * 
     * @param tokenId The token id
     * @param Metadata The string type metadata of token
     */
    function setMetadata(uint256 tokenId, string memory Metadata)
        public
        onlyNFTOwner(tokenId)
    {
        require(ownerOf(tokenId) != address(0), "Invalid token ID");

        mapMetadata[tokenId] = Metadata;
    }

    //View

    /**
     * @dev Retrieves value of token metadata
     * 
     * @param tokenId The token id
     * @return The metadata of token
     */
    function getMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "Invalid token ID");
        return mapMetadata[tokenId];
    }
}
