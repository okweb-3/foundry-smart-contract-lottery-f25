// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/**
 * @title A simple Raffle
 * @author okweb-3
 * @notice This contract is for learning purposes only
 * @dev Implemets ChainLink VRFv2.5
 */
contract Raffle {
    uint256 private immutable i_entranceFee;
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }
    function enterRaffle() public payable {}

    function pickWinner() public {}
    /** Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
