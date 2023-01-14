// SPDX-License-Identifier: MIT
//质押ERC20得到ERC20
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {

    IERC20 ERC20;
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

    function setERC20(address erc20) public {
        ERC20 = IERC20(erc20);
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
        ERC20.transferFrom(msg.sender, address(this), amount);//质押erc20
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
        ERC20.transfer(msg.sender, benefit);
        benefitHadGet[msg.sender] += benefit; 

    }

    //查看可以领取的收益
    function benefitCanGot() public view returns(uint) {
        return userPrize() - benefitHadGet[msg.sender];
    }



}
