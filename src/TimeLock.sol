// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {TimelockController} from "../lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    //constructor from TimelockController use the following:
    //minDelay = 2 days // min delay to wait before execution
    //proposers = msg.sender // list of addresses that can do proposals
    //executors = msg.sender // list of addresses that can do executions
    // it also requires an admin address, msg.sender for now
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
