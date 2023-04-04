// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./SmartOnly.sol";
import "./PrimaryNFT.sol";


contract Certificate is PrimaryNFT {

    constructor() PrimaryNFT("Metable Certificate", "CRT") {}

   /**
     * @dev Mint NFT of the completed course
     *      courseId must be in 0-2^48 range
     * 
     * Emits a {Transfer} event.
     * 
     * @param to The target address that will receive the tokens
     * @param courseId The uint256 ID of the course token
     */
    function Mint(address to, uint256 courseId) external onlyOwner {

        uint256 tokenId = (_NewID() << 48) + courseId;
        _mint(to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function Burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }



   /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override 
    {
        if(from==address(0))
            return;
        if(to==address(0))
            return;

        revert("Token transfer is prohibited");
    }


}
