// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PrimaryNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    string private _BaseURI;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _tokenIdCounter = 1; //start NFT from ID=1
    }

    //Throws if called by any account other than the NFT owner
    modifier onlyNFTOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Error NFT owner");
        _;
    }

    function _NewToken(address to) internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _mint(to, tokenId);
    }

    function _NewID() internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        _tokenIdCounter++;
    }

    //Standart NFT work
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _BaseURI = baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _BaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _BaseURI;
    }

}
