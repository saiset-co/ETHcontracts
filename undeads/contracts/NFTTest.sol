// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PrimaryNFT.sol";


contract NFTTest is PrimaryNFT {

    constructor() PrimaryNFT("Sample NFT", "NFT") {}

    function Mint(address to) external onlyOwner 
    {
        _NewToken(to);
    }

    function Burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function getPrice(uint256 ) external pure returns(uint256)
    {
        return 100e18;
    }


}
