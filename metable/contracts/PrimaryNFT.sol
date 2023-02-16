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

     /**
     * @dev Mint new NFT
     * 
     * Emits a {Transfer} event.
     * 
     * @param to The target address that will receive the tokens
     * @return tokenId The uint256 ID of the token
     */
    function _NewToken(address to) internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _mint(to, tokenId);
    }

    /**
     * Token ID counter in order
     */
    function _NewID() internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter;
        _tokenIdCounter++;
    }

    //Standart NFT work

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _BaseURI = baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function baseTokenURI() public view returns (string memory) {
        return _BaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _BaseURI;
    }

}
