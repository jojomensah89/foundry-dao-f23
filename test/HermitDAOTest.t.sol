// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
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

    uint256 public constant MIN_DELAY = 3600; // 1 hour after vote in secs

    function setUp() public {
       hermitToken = new HermitToken();
       hermitToken.mint(USER,INITIAL_SUPPLY);

       vm.startPrank(USER); 
       hermitToken.delegater(USER);

       timeLock =  new TimeLock(MIN_DELAY,proposers,executors);
       hermitDAO = new HermitDAO(hermitToken,timeLock);
    }

 
}
