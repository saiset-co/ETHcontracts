// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PrimaryNFT.sol";


contract SampleNFT is PrimaryNFT {

    constructor() PrimaryNFT("Sample NFT", "NFT") {}

    function Mint(address to) external onlyOwner 
    {
        _NewToken(to);
    }

    function Burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
