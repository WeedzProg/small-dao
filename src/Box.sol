// SPDX-License-Identifier: MIT
// Contract controlled by the DAO, so it should be ownable
pragma solidity ^0.8.18;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private number;

    event NumberChanged(uint256 newNumber);

    //below function is only callabe by the DAO
    function store(uint256 newNumber) public onlyOwner {
        number = newNumber;
        emit NumberChanged(newNumber);
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}
