// SPDX-License-Identifier: MIT
//质押ERC20A得到ERC20B
//可以解除质押
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {

    IERC20 stakeERC20;
    IERC20 profitERC20;
    uint public count;
    address public owner;
    uint public lastTime;
    uint public publicOneEthEarnings;
    uint public secondPrize = 1000000000000000000;//每秒收益1 eth
    uint util = 1000000000000000000;

    mapping(address => uint) public userLastTimePrize;
    mapping(address => uint) public userOneEthPrize;
    mapping(address => uint) public userBalance;
    mapping(address => uint) public userInterest;
    mapping(address => uint) public benefitHadGet;//用户已经领取的收益

    constructor(){
        owner = msg.sender;
    }

    receive() external payable {

    }

    function setStakeERC20(address erc20) public {
        stakeERC20 = IERC20(erc20);
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

    function stake(uint amount) public {
        stakeERC20.transferFrom(msg.sender, address(this), amount);//质押erc20
        //require(msg.value > 0, "msg.value >0");
        publicOneEthEarnings = findntPublicOneEthEarnings();
        lastTime = block.timestamp;
        userLastTimePrize[msg.sender] = userPrize();
        userOneEthPrize[msg.sender] = findntPublicOneEthEarnings();
        userBalance[msg.sender] += amount;
        count += amount;//总存款
    }
    //领取收益
    function getBenefit() public {
        uint benefit = userPrize() - benefitHadGet[msg.sender];
        profitERC20.transfer(msg.sender, benefit);//奖励的erc20
        benefitHadGet[msg.sender] += benefit; 

    }

    //查看可以领取的收益
    function benefitCanGot() public view returns(uint) {
        return userPrize() - benefitHadGet[msg.sender];
    }

    function withdrawStakeERC20() public {
        getBenefit();
        stakeERC20.transfer(msg.sender, userBalance[msg.sender]);
        userBalance[msg.sender] = 0;
    }



}
