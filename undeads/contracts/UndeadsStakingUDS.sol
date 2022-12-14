// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./UndeadsStaking.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//import "hardhat/console.sol";


interface UndeadNFT is IERC721 {
    function getPrice(uint256 id) external returns(uint256);
}

interface IRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


contract UndeadsStakingUDS is UndeadsStaking
{
    using SafeERC20 for IERC20;
 

    IERC20 public smartUDS;
    UndeadNFT public smartNFT;
    IRouter public smartAMM;
    address[] public pathAMM;


    constructor(address addrUDS,address addrUGOLD, address addrNFT, address addrAMM)
    {
        smartUDS=IERC20(addrUDS);
        smartNFT=UndeadNFT(addrNFT);
        smartAMM=IRouter(addrAMM);

        pathAMM=[addrUDS,addrUGOLD];
    }



    function stake(uint256 _amount,uint256 _periodDay, uint256 idNFT)  external
    {
        //transfer coins from client
        smartUDS.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 AmountUse=_amount;
        if(idNFT>0)
        {
            //transfer NFT from client
            smartNFT.transferFrom(msg.sender,address(this),idNFT);

            AmountUse += smartNFT.getPrice(idNFT);
        }

        _stake(_amount,AmountUse,_periodDay, idNFT);
    }




    function reward(uint32 sessionId)  external
    {
        _reward(sessionId,false);
    }

    function _reward(uint32 sessionId, bool bSilient)  private
    {
        SSession storage Session=MapSession[msg.sender][sessionId];
        
        require(block.timestamp > Session.Start + windowEnd, "Error reward time");



        //calc reward
        uint256 amount = _getReward(Session);
        if(Session.Withdraw>=amount)
        {
            if(!bSilient)
                revert("There is nothing to withdraw reward");
            return;
        }


        uint256 delta = amount-Session.Withdraw;
        if(Session.idNFT>0)
        {
            //AMM swap
            smartUDS.safeIncreaseAllowance(address(smartAMM),delta);
            smartAMM.swapExactTokensForTokens(delta, 0, pathAMM, msg.sender,block.timestamp);
        }
        else {
            //transfer coins to client
            smartUDS.safeTransfer(msg.sender, delta);
        }


        emit Reward(msg.sender, sessionId, delta, Session.idNFT, (Session.End-Session.Start)/86400);

        Session.Withdraw += uint128(delta);
    }

    


    function unstake(uint32 sessionId)  external
    {
        SSession memory Session=MapSession[msg.sender][sessionId];
        require(Session.End>0,"Error sessionId");
        require(block.timestamp > Session.End, "Error unstaking time");

        //refund reward
        _reward(sessionId,true);

        _unstake(Session,sessionId);

        if(Session.Body>0)
        {
            //transfer coins staking body to client
            smartUDS.safeTransfer(msg.sender, Session.Body);
        }

        if(Session.idNFT>0)
        {
            //transfer NFT staking body to client
            smartNFT.transferFrom(address(this),msg.sender,Session.idNFT);
        }

    }




}


