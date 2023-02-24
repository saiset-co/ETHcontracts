// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SmartOnly.sol";

///@dev A token interface that can be managed by a smart contract
interface ISmartToken {
    function SmartTransferTo(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

///@dev Short version of the NFT standard interface
interface INFTToken {

    function ownerOf(uint256 tokenId) external returns (address);
}


contract Tickets is ERC1155, Ownable, SmartOnly {
    INFTToken smartMetable;
    INFTToken smartCourse;
    ISmartToken public smartToken;
    
    ///@dev Storage info about issue course tickets
    mapping(uint256 => uint256) internal mapAmount;
    mapping(uint256 => uint256) internal mapPrice;

    constructor(address addrMetable, address addrToken, address addrCourse) ERC1155("") {
        smartMetable = INFTToken(addrMetable);
        smartToken = ISmartToken(addrToken);
        smartCourse = INFTToken(addrCourse);
    }

    /**
     * @dev Request to issue course tickets
     * 
     * @param courseId The course ID
     * @param amount The number of tickets
     * @param price The price
     */
    function issueTickets(
        uint256 courseId,
        uint256 amount,
        uint256 price
    ) public {
        require(amount > 0, "issueTickets::Error amount issue");
        require(price > 0, "issueTickets::Error zero price");
        require(
            smartCourse.ownerOf(courseId) == msg.sender,
            "issueTickets::Error Course owner"
        );
        mapAmount[courseId] = amount;
        mapPrice[courseId] = price;
    }

    
    /**
     * @dev Confirmation of the request from the school owner
     * 
     * @param schoolId The school ID
     * @param courseId The course ID
     */
    function approveTickets(uint256 schoolId, uint256 courseId) public {
        uint256 amount = mapAmount[courseId];
        require(amount > 0, "approveTickets::Error amount issue");
        require(smartMetable.ownerOf(schoolId) == msg.sender,"approveTickets::Error school owner");

        address to = address(this);
        _mint(to, courseId, amount, "");
        mapAmount[courseId] = 0;
    }

     /**
     * @dev Token transfer, called from other smart contracts
     * 
     * @param from The sender's address
     * @param to The recipient's address
     * @param tokenId The id of token
     * @param amount The amount of token
     */
    function SmartTransferTo(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlySmart returns (bool) {
        _safeTransferFrom(from, to, tokenId, amount, "");

        return true;
    }

    function buyTickets(uint256 courseId, uint256 amount) external {
        //require(smartCourse.ownerOf(courseId) != address(0), "buyTickets::Error course ID");
        require(amount > 0, "buyTickets::Amount is zero");
        uint256 SalePrice = mapPrice[courseId];
        require(SalePrice > 0, "buyTickets::Sale Price is zero");


        require(
            balanceOf(address(this), courseId) >= amount,
            "buyTickets::Not enough tickets on a smart contract"
        );

        //Get GameToken from client
        require(
            smartToken.SmartTransferTo(
                msg.sender,
                smartCourse.ownerOf(courseId),
                SalePrice * amount
            ),
            "buyTickets::Error transfer Token"
        );

        //Send tickets to client
        _safeTransferFrom(address(this), msg.sender, courseId, amount, "");
    }

    //Standart

    /**
     * @dev See {IERC1155Receiver}
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) virtual public pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver}
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }


 
}
