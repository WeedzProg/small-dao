// SPDX-License-Identifier: MIT

// basic airdrop contract, refactored for gas optimizations
// gas differences conclusion:
// after test the Bad function will have cost: 1570606 gas
// and the good function: 880810 gas nearly divided by 2
pragma solidity ^0.8.18;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AirDropGas {
    //address token; // bad use for gas
    address public immutable token; // better use, if the value never change after deployment better to set variables immutable , they are directly initialized in the constructor and easier to cheaper to read from each time in the bytecode
    uint256 public transfers;

    error AirDropGas__InvalidLengths();

    constructor(address _token) {
        token = _token;
    }

    function badAirdrop(address[] memory _recipients, uint256[] memory _amounts) public {
        if (_recipients.length != _amounts.length) {
            revert AirDropGas__InvalidLengths();
        }
        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(token).transferFrom(msg.sender, address(this), _amounts[i]);
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(token).transfer(_recipients[i], _amounts[i]);
            transfers++;
        }
    }

    // in the goodAirDrop function we changed two arguments for "calldata" and added an integer for the totalAmount. This is because the calldata is cheaper to read from than memory and we can use the totalAmount to check if the length of the two arrays are the same. This is a gas optimization because we are using less gas to read from calldata and we are not using a for loop to check the length of the arrays.
    function goodAirdrop(
        address[] calldata _recipients,
        uint256[] calldata _amounts,
        uint256 totalAmount
    ) public {
        if (_recipients.length != _amounts.length) {
            revert AirDropGas__InvalidLengths();
        }
        //transferring the total amount to airdrop to the contract
        IERC20(token).transferFrom(msg.sender, address(this), totalAmount);

        //transffering from the contract to the receiver the required amount
        for (uint256 i; i < _recipients.length; ) {
            IERC20(token).transfer(_recipients[i], _amounts[i]);
            //the odds to overflow is very low, because it can be really difficult to reach the max of uint256 as number of addresses to airdrop too
            unchecked {
                i++;
            }
        }

        //so same as the previous unchecked it is nearly impossible to reach a number of iteration of the function up to the max uint256 so it can be marked unchecked.
        // in addition the variable update is just done once, at the very end after everything is done, so it is not necessary to update it at each iteration of the loop
        unchecked {
            transfers += _recipients.length;
        }
    }
}
