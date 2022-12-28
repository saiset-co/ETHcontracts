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

    function craft(address owner_, uint256 subClass) external returns(uint256)
    {
        return _NewToken(owner_);
    }
    



    function craft(
            address owner_,
            uint256 class_,
            uint256 subclass_,
            uint256 location_,
            uint16[10] memory props_,
            uint8 slots_,
            uint256 count_,
            string memory image_,
            string memory dynamic_
        ) external returns (uint256) {
            //require(location_ > 0 || count_ == 1, "ONLY_ONE_CARRYABLE");
            return _NewToken(owner_);
            /*
            bytes32 currentKey = key(owner_, location_, class_, subclass_);
            // only for location-based items already created at this place
            if (location_ > 0 && _keys[currentKey] != 0) {
                _mint(owner_, _keys[currentKey], count_, "");
                emit Crafted(owner_, _keys[currentKey], count_);
                return _keys[currentKey];
            }
            // location-independent item or not createad yet at this position item
            return
                _craft(
                    owner_,
                    class_,
                    subclass_,
                    location_,
                    props_,
                    slots_,
                    count_,
                    image_,
                    dynamic_
                );
            */

        }

    }
