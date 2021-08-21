// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Governance {
    IERC20 public DTtoken;
    // voter => deposit
    mapping(address => uint256) public deposits;

    // Voter => Withdraw timestamp
    mapping(address => uint256) public withdrawTimes;

    constructor(IERC20 _DTtoken) {
        DTtoken = _DTtoken;
    }

    function deposit(uint256 _amount) external {
        deposits[msg.sender] += _amount;
        DTtoken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external {
        deposits[msg.sender] -= deposits[msg.sender];
        DTtoken.transfer(msg.sender, _amount);
    }
}