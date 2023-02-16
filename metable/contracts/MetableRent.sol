// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetableSale.sol";

contract MetableRent is MetableSale {
    INFTToken public smartCourse;

    ///@dev Storing rent info of token
    struct SRentItem {
        uint16 MaxRents;
        address[] users;
        uint64[] expires;
    }

    mapping(uint256 => SRentItem) internal MapRents;

    constructor(address addrToken, address addrCourse) MetableSale(addrToken) {
        smartCourse = INFTToken(addrCourse);
    }


    /**
     * @dev Placing an order for the rent of a token (internal use)
     * 
     * @param tokenId The child token
     * @param index The rent slot index
     * @param user The NFT owner addres
     * @param expires The rent end date (sec)
     */
    function _setRent(
        uint256 tokenId,
        uint256 index,
        address user,
        uint64 expires
    ) internal {
        SRentItem storage info = MapRents[tokenId];
        if (index < info.users.length) {
            require(
                rentUser(tokenId, index) == address(0),
                "_setRent::The slot has already been rented"
            );

            info.users[index] = user;
            info.expires[index] = expires;
        } else {
            require(
                info.MaxRents > info.users.length,
                "_setRent::No rents slot available"
            );

            info.users.push(user);
            info.expires.push(expires);
        }
    }

    //View

    /**
     * @dev Retrieves info of token rent
     * 
     * @param tokenId The token id
     * @return info The rent info {SRentItem}
     */
    function rentToken(uint256 tokenId)
        public
        view
        returns (SRentItem memory info)
    {
        info = MapRents[tokenId];
    }

    /**
     * @dev Retrieves renter of token
     * 
     * @param tokenId The token id
     * @param index The rent slot index
     * @return The renter address
     */
    function rentUser(uint256 tokenId, uint256 index)
        public
        view
        returns (address)
    {
        SRentItem memory info = MapRents[tokenId];

        if (uint256(info.expires[index]) >= block.timestamp) {
            return info.users[index];
        } else {
            return address(0);
        }
    }

    /**
     * @dev Retrieves the end date of the lease
     * 
     * @param tokenId The token id
     * @param index The rent slot index
     * @return The lease date
     */
     function rentExpires(uint256 tokenId, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        SRentItem memory info = MapRents[tokenId];
        return info.expires[index];
    }

}
