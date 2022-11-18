// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./investgame.sol";

//import "hardhat/console.sol";

contract Voting is ERC20 {
    uint256 public ProposalPrice;
    uint256 public ProposalPeriod;
    InvestGame Child;
    enum EnumType {
        None,
        SetProposalPrice,
        SetProposalPeriod,
        MintTo,
        TransferFromTo,
        Withdraw,
        setListingPrice,
        setTradeToken,
        delTradeToken,
        approveTradeToken,
        withdrawInvest,
        Last
    }

    struct SProposal {
        EnumType method;
        address addr1;
        address addr2;
        uint256 amount;
        string message;
        uint128 vote0;
        uint128 vote1;
    }

    struct SProposalInfo {
        bytes32 key;
        uint256 expires;
        SProposal data;
    }

    mapping(bytes32 => SProposal) MapProposal;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    EnumerableMap.Bytes32ToUintMap private EnumMapProposal;

    //      proposel           client     amount
    mapping(bytes32 => mapping(address => uint256)) private MapClientVoted;
    //      client     time
    mapping(address => uint256) private MapFreezeTime;

    constructor(address _Child) ERC20("Invest DAO token", "iDAO") {
        Child = InvestGame(_Child);
        _mint(msg.sender, 100000 * 10**18);
    }

    //External
    function proposal(
        EnumType method,
        address addr1,
        address addr2,
        uint256 amount,
        string memory message
    ) external payable {
        require(ProposalPrice >= msg.value, "Error of the received ETH amount");
        require(
            method > EnumType.None && method < EnumType.Last,
            "Error key proposal"
        );

        SProposal memory data = SProposal(
            method,
            addr1,
            addr2,
            amount,
            message,
            0,
            1
        );

        bytes32 key = keccak256(abi.encode(data));
        require(MapProposal[key].method == EnumType.None, "Duplicate proposal");

        MapProposal[key] = data;

        uint256 expires = block.number + ProposalPeriod;
        EnumMapProposal.set(key, expires);
    }

    function vote(
        bytes32 key,
        uint256 isYes,
        uint256 amount
    ) external {
        require(amount > 0, "Zero amount");
        SProposal storage data = MapProposal[key];
        require(data.method > EnumType.None, "Error key proposal");

        uint256 expires = EnumMapProposal.get(key);
        require(block.number < expires, "Error block expires");

        //Client balance
        uint256 clientBalance = balanceOf(msg.sender);
        require(clientBalance >= amount, "Vote amount exceeds balance");

        uint256 clientVoting = MapClientVoted[key][msg.sender] + amount;
        require(clientBalance >= clientVoting, "Total vote amount exceeds balance");
        MapClientVoted[key][msg.sender] = clientVoting;
        MapFreezeTime[msg.sender] = expires;

        if (isYes == 0) {
            data.vote0 += uint128(amount);
        } else {
            data.vote1 += uint128(amount);
        }
    }

    function approveVote(bytes32 key) external {
        SProposal memory data = MapProposal[key];
        require(data.method > EnumType.None, "Error key proposal");

        uint256 expires = EnumMapProposal.get(key);
        require(block.number >= expires, "Error block expires");

        if (data.vote1 > data.vote0) {
            if (data.method == EnumType.SetProposalPrice) {
                _SetProposalPrice(data.amount);
            } else if (data.method == EnumType.SetProposalPeriod) {
                _SetProposalPeriod(data.amount);
            } else if (data.method == EnumType.MintTo) {
                _MintTo(data.addr1, data.amount);
            } else if (data.method == EnumType.TransferFromTo) {
                _TransferFromTo(data.addr1, data.addr2, data.amount);
            } else if (data.method == EnumType.Withdraw) {
                _Withdraw(data.addr1, data.amount);
            }
            //Child
            else if (data.method == EnumType.setListingPrice) {
                Child.setListingPrice(data.addr1, data.amount);
            }

            if (data.method == EnumType.setTradeToken) {
                Child.setTradeToken(data.addr1, data.message);
            }
            if (data.method == EnumType.delTradeToken) {
                Child.delTradeToken(data.addr1);
            }
            if (data.method == EnumType.approveTradeToken) {
                Child.approveTradeToken(data.addr1, data.message);
            }
            if (data.method == EnumType.withdrawInvest) {
                Child.withdrawInvest(data.addr1, data.addr2, data.amount);
            }
        }

        EnumMapProposal.remove(key);
        delete MapProposal[key];
    }

    //Internal
    function _SetProposalPrice(uint256 _price) internal {
        ProposalPrice = _price;
    }

    function _SetProposalPeriod(uint256 _period) internal {
        ProposalPeriod = _period;
    }

    function _MintTo(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    function _TransferFromTo(
        address from,
        address to,
        uint256 amount
    ) internal {
        MapFreezeTime[from] = 0;
        _transfer(from, to, amount);
    }

    function _Withdraw(
        address addrTo,
        uint256 amount
    ) internal {
        payable(addrTo).transfer(amount);
    }

    //View
    function balanceFee() public view returns (uint256) {
        return address(this).balance;
    }

    function lengthProposal() public view returns (uint256) {
        return EnumMapProposal.length();
    }

    function listProposal(uint256 startIndex, uint256 counts)
        public
        view
        returns (SProposalInfo[] memory Arr)
    {
        uint256 length = EnumMapProposal.length();

        if (startIndex < length) {
            if (startIndex + counts > length) counts = length - startIndex;

            bytes32 key;
            uint256 expires;
            Arr = new SProposalInfo[](counts);
            for (uint256 i = 0; i < counts; i++) {
                (key, expires) = EnumMapProposal.at(startIndex + i);
                Arr[i].key = key;
                Arr[i].expires = expires;
                Arr[i].data = MapProposal[key];
            }
        }
    }


     //Override ERC20
     function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal view override 
    {
        //check freeze time-amount
        uint256 expires = MapFreezeTime[from];
        require(block.number >= expires, "Block number error. Tokens are still frozen.");
    }    
}
