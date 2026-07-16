// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStrategy {

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount,address to) external;

    function harvest() external;

    function balance() external view returns(uint256);

}
