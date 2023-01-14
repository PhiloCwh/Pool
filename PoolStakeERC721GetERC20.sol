// SPDX-License-Identifier: MIT

/*使用说明，部署ERC20和ERC721合约，调用setERC721和setERC20方法
完成初始化
*/
//质押ERC721得到ERC20
//可以解除质押
    //注意但钱包为0时，更新benefit也为0，不然benefitcanget方法会下溢
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Pool {
    IERC721 stakeERC721;//质押的NFT
    //IERC20 stakeERC20;
    IERC20 profitERC20;
    uint public count;
    address public owner;
    uint public lastTime;
    uint public publicOneEthEarnings;
    uint public secondPrize = 1000000000000000000;//每秒收益1 eth
    uint util = 1000000000000000000;
    uint constant ONE_ETH = 1 * 10**18; 

    mapping(address => uint) public userLastTimePrize;
    mapping(address => uint) public userOneEthPrize;
    mapping(address => uint) public userBalance;
    mapping(address => uint) public userInterest;
    mapping(address => uint) public benefitHadGet;//用户已经领取的收益
    mapping(address => mapping(uint => bool)) public NFTIsStake;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable {

    }

    function setstakeERC721(address erc721) public {
        stakeERC721 = IERC721(erc721);
    }

    function setProfitERC20(address erc20) public {
        profitERC20 = IERC20(erc20);
    }

    function Initialize (uint sprize) public {
        require(msg.sender == owner,"motherFuker");
        publicOneEthEarnings = findntPublicOneEthEarnings();
        lastTime = block.timestamp;
        secondPrize = sprize;
    }

    //查询公共一块钱奖励
    function findntPublicOneEthEarnings() public view returns(uint) {
        if(count == 0)
            return publicOneEthEarnings;
        return (publicOneEthEarnings + ((block.timestamp - lastTime) * secondPrize * util)/count);
    }

    function userPrize() public view returns(uint256) {
        if(userBalance[msg.sender] == 0)
            return 0;
        uint userOutput = (findntPublicOneEthEarnings() - userOneEthPrize[msg.sender]) / util;
        return (userBalance[msg.sender] * userOutput + userLastTimePrize[msg.sender]);
    }//userLastTimePrize[msg.sender]用户之前收益

    function stake(uint tokenId) public {
        require(stakeERC721.ownerOf(tokenId) == msg.sender,"not owner");
        stakeERC721.transferFrom(msg.sender, address(this), tokenId);//质押erc20
        //require(msg.value > 0, "msg.value >0");
        publicOneEthEarnings = findntPublicOneEthEarnings();
        lastTime = block.timestamp;
        userLastTimePrize[msg.sender] = userPrize();
        userOneEthPrize[msg.sender] = findntPublicOneEthEarnings();
        NFTIsStake[msg.sender][tokenId] = true;//作为withdraw的标记
        userBalance[msg.sender] += ONE_ETH;
        count += ONE_ETH;//总存款
    }
    //领取收益
    function getBenefit() public {
        uint benefit = userPrize() - benefitHadGet[msg.sender];
        profitERC20.transfer(msg.sender, benefit);//奖励的erc20
        benefitHadGet[msg.sender] += benefit; 

    }

    //查看可以领取的收益
    function benefitCanGet() public view returns(uint) {
        if (userPrize() == 0)
            return 0;
        return userPrize() - benefitHadGet[msg.sender];
    }
    //注意但钱包为0时，更新benefit也为0，不然benefitcanget方法会下溢
    function withdrawstakeERC721(uint tokenId) public {
        require(NFTIsStake[msg.sender][tokenId] = true, "not stake For you");
        getBenefit();//领取ERC20
        stakeERC721.transferFrom(address(this), msg.sender, tokenId);
        //profitERC20.transfer(msg.sender,)
        userBalance[msg.sender] -= ONE_ETH;
        count -= ONE_ETH;
        if (userPrize() == 0)
            benefitHadGet[msg.sender] = 0;
    }



}
