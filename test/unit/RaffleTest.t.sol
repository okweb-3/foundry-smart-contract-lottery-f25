//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig helperConfig = new HelperConfig();

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetWorkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }
    function testRaffleInitializesOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testRaffleRevertsWhenYouDontPayEnough() public {
        //Arrange
        // 告诉 Foundry 的虚拟机模拟下面的调用是由 PLAYER 地址发出的，而不是测试合约自身
        vm.prank(PLAYER);
        //Act
        //Assert
        // 这是断言阶段（Assert），它告诉测试框架「我希望接下来的函数调用会发生 Raffle__SendMoreToEnterRaffle 这个错误」。
        // 其中：
        // vm.expectRevert(...) 是 Foundry 提供的一个测试工具函数，用于预期抛出错误。
        // Raffle.Raffle__SendMoreToEnterRaffle.selector 是自定义错误的 selector，相当于错误的标识符。
        vm.expectRevert(Raffle.Raffle__SenderMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }
    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }
    //Testing events
    //当你想测试一个函数是否会成功发出你期望的事件，就可以使用expectEmit
    function testEnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //Assert
        raffle.enterRaffle{value: entranceFee}();
    }
    function testDontAllowPlayersToEnterWhileIsCalculating() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act /Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    /*//////////////////////////////////////////////////////////////
                            PERFORM UPKEEPER
    //////////////////////////////////////////////////////////////*/
    function testPerformUpkeeperCanOnlyRunIfCheckUpKeepIsTrue()public{
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        //Assert
        raffle.performUpkeep("");
    }
    function testPerformUpkeeperRevertsIfCheckUpkeepIsFalse()public{
        //Arrange
        uint256 currentBalance=0;
        uint256 numPlayers=0;
        Raffle.RaffleState rState=raffle.getRaffleState();


        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance+entranceFee;
        numPlayers = 1;
        //Act
        //Assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeed.selector,currentBalance,numPlayers,rState));
        raffle.performUpkeep("");

    }
      modifier raffleEntered() {
         vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
    function testPerformUpkeepeUpdatesRaffleStateAndEmitsRequestId()public raffleEntered{
        //Arrange
       
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");   
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId=entries[1].topics[1];
        //assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId)>0);
        assert(uint256(raffleState)==1);
    }
   /*//////////////////////////////////////////////////////////////
                          FULLFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/
    function testFulfullrandomWordsCanonlyBecalledAfterPerformUpkeeper(uint256 randomRequestId)public raffleEntered{
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
    }
}
