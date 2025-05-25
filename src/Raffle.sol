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

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // errors
    error Raffle__SenderMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeed(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );
    // Type declarations
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }
    // State variables
    // uint16 private constant REQUSER_CONFIRMATIONS = 3;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    bytes32 private immutable i_KeyHash;
    uint256 private immutable i_subscriptionId;
    uint256 private immutable i_entranceFee;
    uint32 private immutable i_callbackGasLimit;
    //@dev The duration of the lottery period in seconds
    uint256 private immutable i_interval;
    //玩家数组
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_RaffleState;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_KeyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_RaffleState = RaffleState.OPEN;
    }
    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough funds!");
        // require(msg.value >= i_entranceFee, SenderMoreToEnterRaffle（）);
        if (msg.value < i_entranceFee) {
            revert Raffle__SenderMoreToEnterRaffle();
        }
        if (s_RaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
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
    //什么时候选出获胜者
    /**
     * @dev 这个函数将会被chainlink节点调用
     * 这个抽奖准备好才会选出获胜者
     * 以下的要求满足了 upkeepNeeded才能为真
     1. 抽奖运行之间的间隔已经过去
     2. 彩票仍然开放
     3. 合约中有eth
     4. 隐藏的条件，你的订阅里要有link */
    function checkUpkeep(
        bytes memory
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_RaffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) public {
        //pick a winner here, send him the reward and reset the raffle
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeed(
                address(this).balance,
                s_players.length,
                uint256(s_RaffleState)
            );
        }

        s_RaffleState = RaffleState.CALCULATING;
        //向合约发起请求
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                //下面都参数
                keyHash: i_KeyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        //s_vrfCoordinator 是继承来的
        uint256 requestId=s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }
    //处理响应
    // CEI：Checks Effects Interactions
    // CEI - Check Effects Interactions，检查效果互动或效应交互等的缩写。
    //它是用于验证合约在特定条件下是否满足其预期行为的一种机制；
    //例如通过调用一个函数来确认某个事件已经发生并触发了预期的结果

    function fulfillRandomWords(
        uint256,
        /* requestId */ uint256[] calldata randomWords
    ) internal override {
        //checks

        //利用取余运算符来确定获胜者

        //Effect (Internal Contract State)
        uint256 indexOfwinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfwinner];
        s_recentWinner = recentWinner;
        s_RaffleState = RaffleState.OPEN;
        //清空队列
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        //Interactions (External Contract interactions);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
    function getRaffleState() external view returns (RaffleState) {
        return s_RaffleState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
