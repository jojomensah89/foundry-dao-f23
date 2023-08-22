// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HermitDAO} from "../src/HermitDAO.sol";
import {HermitToken} from "../src/HermitToken.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract HermitDAOTest is Test {

    HermitDAO hermitDAO;
    HermitToken hermitToken;
    SimpleStorage simpleStorage;
    TimeLock timeLock;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    address[] proposers;
    address[] executors;
    
    uint256[] values;
    bytes[] calldatas;
    address[] targets;
    

    uint256 public constant MIN_DELAY = 3600; // 1 hour after vote in secs
    uint256 public constant VOTING_DELAY = 7200; //  How many blocks till a proposal vote becomes active 1 block = 12 (24 hrs = 86400 secs) seconds hence
    uint256 public constant VOTING_PERIOD = 50400; // How long voting lasts in secs

    function setUp() public {
       hermitToken = new HermitToken();
       hermitToken.mint(USER,INITIAL_SUPPLY);

       vm.prank(USER); 
       hermitToken.delegate(USER);

       timeLock =  new TimeLock(MIN_DELAY,proposers,executors);
       hermitDAO = new HermitDAO(hermitToken,timeLock);

       bytes32 proposerRole = timeLock.PROPOSER_ROLE();
       bytes32 executorRole = timeLock.EXECUTOR_ROLE();
       bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();

       timeLock.grantRole(proposerRole,address(hermitDAO));
       timeLock.grantRole(executorRole,address(0));
       timeLock.revokeRole(adminRole,USER);


       simpleStorage = new SimpleStorage();
       simpleStorage.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        simpleStorage.store(5);
    }

    function testHermitDAOCanUpdateSimpleStorage() public{
        uint256 valueToStore = 444;
        string memory description = "store number 444";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)",valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(simpleStorage));

        // 1. make proposal
        uint256 proposalId = hermitDAO.propose(targets,values,calldatas,description);

        // view proposal state
        console.log("Proposal State: ", uint256(hermitDAO.state(proposalId)));

        // speed up block formation
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        console.log("block number:",block.number);
        console.log("block time:",block.timestamp);

        console.log("Proposal State: ", uint256(hermitDAO.state(proposalId)));

        //2. cast vote with reason
        string memory reason = "number is cool";
              
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1; //voting yes

        vm.prank(USER);
        hermitDAO.castVoteWithReason(proposalId,voteWay,reason);

        // speed up voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State: ", uint256(hermitDAO.state(proposalId)));

        //3. Queue Proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        hermitDAO.queue(targets,values,calldatas,descriptionHash);

        
        // speed up block formation
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        //4. Execute Proposal
        hermitDAO.execute(targets,values,calldatas,descriptionHash);

        assertEq(simpleStorage.getNumber(),valueToStore);
        console.log("Storage Value:",simpleStorage.getNumber());

    }

}
