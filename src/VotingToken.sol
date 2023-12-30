// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

//ERC20Permit is used to allow users to sign a transaction without sending it and have someone else sending the transaction instead
//ERC20Votes is used to allow users to vote with their tokens, it takes historical snapshots, to check a specific period who was owning a certain amount. it avoid brutal buy and sell just for voting
//ERC20Votes also allows to delegate votes to another address, let say that if we trust someone in their doing but we arent really understanding the topic. Then we allow the trusted person to vote on our behalf
contract VotingToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("VotingToken", "VTK") ERC20Permit("VotingToken") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    //The below was generated from the openzeppelin token wizard
    // function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
    //     super._update(from, to, value);
    // }

    // function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
    //     return super.nonces(owner);
    // }
}
