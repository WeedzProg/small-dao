// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Box} from "../src/Box.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {VotingToken} from "../src/VotingToken.sol";

contract MyGovernorTest is Test {
    Box box;
    MyGovernor governor;
    TimeLock timeLock;
    VotingToken votingToken;

    address public USER = makeAddr("user");
    uint256 constant INITIAL_SUPPLY = 1000 ether;
    uint256 public min_delay = 3600; //1h after a vote passes
    uint256 public votingDelay = 1; //1 block
    uint256 public votingPeriod = 50400; //1 week

    //proposers & executors
    address[] proposers;
    address[] executors;

    bytes[] calldatas;
    address[] targets;
    uint256[] values;

    function setUp() public {
        votingToken = new VotingToken();
        votingToken.mint(USER, INITIAL_SUPPLY);

        vm.prank(USER);
        //minting tokens to the user doesnt mean the user have a voting power, so we need to delegate it to the user
        votingToken.delegate(USER);

        timeLock = new TimeLock(min_delay, proposers, executors);
        governor = new MyGovernor(votingToken, timeLock);

        //grant roles to the governor once deployed and remove ourself from being the admin
        //avoid central entity to control the contract
        // all bytes32 vars below are used in timelock for a hash function and roles
        //bytes32 role = keccak256("TIMELOCK_ADMIN");

        bytes32 proposerRole = timeLock.PROPOSER_ROLE(); // governor role, only governor can submit to timelock
        bytes32 executorRole = timeLock.EXECUTOR_ROLE(); // anybody can execute to timelock
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE(); // admin role, only admin can grant/revoke roles

        timeLock.grantRole(proposerRole, address(governor));
        timeLock.grantRole(executorRole, address(0)); // address 0 -> anybody
        timeLock.revokeRole(adminRole, address(USER)); // remove ourself from being the admin

        box = new Box();

        // then transfer ownership of the box to timelock, as timelock owns the governor too
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        //try to update the box without governance
        //assert that the box is not updated
        vm.expectRevert();
        box.store(1); // owner of box is timelock, timelock is not governor
        //assertEq(box.retrieve(), 0);
    }

    //the below big test shows the exact process of how a DAO works
    function testGovernanceUpdatesBox() public {
        //value we propose in the proposal
        uint256 valueToStore = 777;
        //description of the proposal
        string memory description = "Store 1 in Box";
        //encode the function call to store the value in the box
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        //blank value pushed to the values array (nas we doesnt send any eth)
        values.push(0);
        //push the encoded function call to the calldatas array
        calldatas.push(encodedFunctionCall);
        //target, call on box
        targets.push(address(box));

        // Then we propose to the DAO by using the propose function that returns a proposalID as an uint256
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // from this stage we can see the state of the proposal
        //states are in IGovernor.sol, see the below list:
        //enum ProposalState {
        //     Pending, // 0
        //     Active, // 1
        //     Canceled, // 2
        //     Defeated, // 3
        //     Succeeded, // 4
        //     Queued, // 5
        //     Expired, // 6
        //     Executed // 7
        // }
        console.log("Proposal State:", uint256(governor.state(proposalId)));
        //should return pending, so 0. has it has a delay (timelock) we needs to pass time of the blockchain forward for other status

        //vm.advanceTime(3600); // 1 hour
        //or using warp and roll. just need to wait 1 block for the voting delay (default waiting time we took from the contract wizard)
        vm.warp(block.timestamp + votingDelay + 1);
        vm.roll(block.number + votingDelay + 1);

        //from here the state should be active, so 1
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // at this point vote is allowed
        string memory voteWithReason = "Ananas on pizza is the best";

        //vote enum, see the below list:
        // against -> 0
        // for -> 1
        // abstain -> 2
        uint8 voteInformation = 1;

        //vote on the proposal
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteInformation, voteWithReason);

        //pass the voting period (default to 1 week from the contract wizard)
        vm.warp(block.timestamp + votingPeriod + 1);
        vm.roll(block.number + votingPeriod + 1);

        // at this stage the vote needs to be queued
        //needs to hash the description first
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // from here the state should be queued, so 5
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //after the proposal has been queued we need to pass the minimum delay for having it execute
        vm.warp(block.timestamp + min_delay + 1);
        vm.roll(block.number + min_delay + 1);

        //from here the state should be succeeded, so 7
        governor.execute(targets, values, calldatas, descriptionHash);
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //assert that the box is updated
        console.log("Box Number:", box.getNumber());
        assertEq(box.getNumber(), valueToStore);
    }
}
