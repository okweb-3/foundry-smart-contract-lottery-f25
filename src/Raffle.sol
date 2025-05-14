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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    // errors
    error Raffle__SenderMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    //@dev The duration of the lottery period in seconds
    uint256 private immutable i_interval;
    //玩家数组
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    // address immutable i_vrfCoordinator;

    //chainlink VRF realted variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint256 private constant REQUSER_CONFIRMARIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }
    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough funds!");
        // require(msg.value >= i_entranceFee, SenderMoreToEnterRaffle（）);
        if (msg.value < i_entranceFee) {
            revert Raffle__SenderMoreToEnterRaffle();
        }
        //将当前合约调用的地址添加到splayers数组中。
        s_players.push(payable(msg.sender));
        //使得迁移更容易，使得索引更容易
        // 玩家成功进入抽奖时触发的事件
        emit RaffleEntered(msg.sender);
    }
    //获取随机数
    //使用随机数
    //自动调用
    //
    function pickWinner() public {
        // s_requestId = s_vrfCoordinator.requestRandomWords(
        //     VRFV2PlusClient.RandomWordsRequest({
        //         keyHash: keyHash,
        //         subId: s_subscriptionId,
        //         requestConfirmations: requestConfirmations,
        //         callbackGasLimit: callbackGasLimit,
        //         numWords: numWords,
        //         extraArgs: VRFV2PlusClient._argsToBytes(
        //             VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        //         )
        //     })
        // );

        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
    }
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}
    /** Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
