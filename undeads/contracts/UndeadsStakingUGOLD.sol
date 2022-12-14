// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./UndeadsStaking.sol";


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



interface IRouter{
    function getAmountsOut(uint amountIn, address[] memory path)  view  external  returns (uint[] memory amounts);
}




contract UndeadsStakingUGOLD is UndeadsStaking
{
    using SafeERC20 for IERC20;
   
    mapping(address => uint256) private MapWallet;



    IERC20 smartGOLD;
    IRouter smartAMM;
    address[] public pathAMM;
    address saleAddress;


    constructor(address addrUDS,address addrUGOLD, address addrSale, address addrAMM)
    {
        smartGOLD=IERC20(addrUGOLD);
        smartAMM=IRouter(addrAMM);

        pathAMM=[addrUGOLD,addrUDS];
        saleAddress=addrSale;
    }
    






    function stake(uint256 _amount,uint256 _periodDay)  external
    {

        //transfer coins from client
        smartGOLD.safeTransferFrom(msg.sender, address(this), _amount);

        uint[] memory amounts = smartAMM.getAmountsOut(_amount, pathAMM);
        uint256 AmountUse=amounts[0];

        _stake(_amount, AmountUse, _periodDay, 0);
    }

 

    function unstake(uint32 sessionId)  external
    {
        SSession memory Stake=MapSession[msg.sender][sessionId];
        require(Stake.End>0,"Error sessionId");
        require(block.timestamp > Stake.End, "Error unstaking time");

        //reward
        MapWallet[msg.sender]+=_getReward(Stake);

        _unstake(Stake,sessionId);

        //transfer coins staking body to client
        smartGOLD.safeTransfer(msg.sender, Stake.Body);
    }



    function burn(address addr, uint256 amount) public
    {
        require(msg.sender==saleAddress,"Error saler address");
        require(MapWallet[addr]>=amount,"Error balance");

        MapWallet[addr] -= amount;
    }





    //View
    function balanceOf(address addr)
        public
        view
        returns (uint256)
    {
        return MapWallet[addr];
    }

   


}


