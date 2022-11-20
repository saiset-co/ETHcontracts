// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./investgame.sol";
import "./KeyList.sol";

//import "hardhat/console.sol";

contract Voting is ERC20 {
    bool inited = false;
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
        withdrawListFee,
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
        uint32 key;
        uint192 expires;
        SProposal data;
    }

    mapping(uint32 => SProposal) MapProposal;

    using KeyList for KeyList.ListItems;
    KeyList.ListItems private ListProposal;


    //      proposel           client     amount
    mapping(uint32 => mapping(address => uint256)) private MapClientVoted;
    //      client     time
    mapping(address => uint256) private MapFreezeTime;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
    constructor() ERC20("Invest DAO token", "iDAO") {
        _mint(msg.sender, 100000 * 10**18);
    }
    function setChild(address _Child) external initializer {
        Child = InvestGame(_Child);
    }

    //External
    function proposalSetPrice(uint256 amount) external payable {
        _createProposal(EnumType.SetProposalPrice,address(0),address(0),amount,"");
    }
    function proposalSetPeriod(uint256 amount) external payable {
        _createProposal(EnumType.SetProposalPeriod,address(0),address(0),amount,"");
    }
    function proposalMintTo(address to, uint256 amount) external payable {
        _createProposal(EnumType.MintTo,to,address(0),amount,"");
    }
    function proposalTransferFromTo(address from,address to, uint256 amount) external payable {
        _createProposal(EnumType.TransferFromTo,from,to,amount,"");
    }
    function proposalWithdraw(address to, uint256 amount) external payable {
        _createProposal(EnumType.Withdraw,to,address(0),amount,"");
    }
    //Child
    function proposalSetListingPrice(address token, uint256 amount) external payable {
        _createProposal(EnumType.setListingPrice,token,address(0),amount,"");
    }
    function proposalSetTradeToken(address token, string memory rank) external payable {
        _createProposal(EnumType.setTradeToken,token,address(0),0,rank);
    }
    function proposalDelTradeToken(address token) external payable {
        _createProposal(EnumType.delTradeToken,token,address(0),0,"");
    }
    function proposalApproveTradeToken(uint32 key, string memory rank) external payable {
        _createProposal(EnumType.approveTradeToken,address(0),address(0),key,rank);
    }
    
    function proposalWithdrawListFee(address token,address to, uint256 amount) external payable {
        _createProposal(EnumType.withdrawListFee,token,to,amount,"");
    }
    
    //Vote
    function vote(
        uint32 key,
        uint8 isYes,
        uint256 amount
    ) external {
        require(amount > 0, "Zero amount");
        SProposal storage data = MapProposal[uint32(key)];
        require(data.method > EnumType.None, "Error key proposal");

        
        uint256 expires = ListProposal.get(uint32(key));
        require(block.timestamp < expires, "Error block time expires");

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

    function approveVote(uint32 key) external {
        SProposal memory data = _getPropasal(key);
        require(data.method > EnumType.None, "Error key proposal");

        uint256 expires = ListProposal.get(key);
        require(block.timestamp >= expires, "Error block time expires");

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
                Child.approveTradeToken(uint32(data.amount), data.message);
            }
            if (data.method == EnumType.withdrawListFee) {
                Child.withdrawListFee(data.addr1, data.addr2, data.amount);
            }
        }

        _delPropasal(key);
    }

    //Internal
    function _createProposal(
        EnumType method,
        address addr1,
        address addr2,
        uint256 amount,
        string memory message
    ) internal {
        //console.log("ProposalPrice = %s, msg.value = %s",ProposalPrice ,msg.value);
        require(msg.value >= ProposalPrice, "Error of the received ETH amount");
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

        //bytes32 key = keccak256(abi.encode(data));
        //require(_getPropasal(key).method == EnumType.None, "Duplicate proposal");
        uint192 expires = uint192(block.timestamp + ProposalPeriod);
        uint32 key=ListProposal.add(expires);

        MapProposal[key] = data;

    }


    function _getPropasal(uint32 key) internal view returns (SProposal memory)
    {
        return MapProposal[key];
    }
    function _delPropasal(uint32 key) internal
    {
        ListProposal.remove(key);
        delete MapProposal[key];
    }


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
    function getPropasal(uint32 key) public view returns (SProposal memory)
    {
        return _getPropasal(key);
    }

    function balanceFee() public view returns (uint256) {
        return address(this).balance;
    }


    function listProposal(uint32 startKey, uint32 counts)
        public
        view
        returns (SProposalInfo[] memory Arr)
    {
        (KeyList.SItemValue[] memory KeyArr, uint32 retCount) = ListProposal.getItems(startKey,counts);

        if (retCount>0) {
            Arr = new SProposalInfo[](retCount);
            for (uint256 i = 0; i < retCount; i++) {
                Arr[i].key = KeyArr[i].key;
                Arr[i].expires = KeyArr[i].value;
                Arr[i].data = _getPropasal(Arr[i].key);
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
        require(block.timestamp >= expires, "Block times error. Tokens are still frozen.");
    }    
}
