// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/**
 * @title A simple Raffle
 * @author okweb-3
 * @notice This contract is for learning purposes only
 * @dev Implemets ChainLink VRFv2.5
 */

contract Raffle {
    // errors
    error Raffle__Raffle__SenderMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }
    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough funds!");
        // require(msg.value >= i_entranceFee, SenderMoreToEnterRaffle（）);
        if (msg.value < i_entranceFee) {
            revert Raffle__SenderMoreToEnterRaffle();
        }
    }

    function pickWinner() public {}
    /** Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
