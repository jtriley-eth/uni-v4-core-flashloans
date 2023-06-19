// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {PoolManager} from "lib/v4-core/contracts/PoolManager.sol";
import {Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {MockERC20} from "test/mock/MockERC20.sol";
import {MockFlash} from "test/mock/MockFlash.sol";
import {MockHandler} from "test/mock/MockHandler.sol";

contract SimpleFlashTest is Test {
    PoolManager pool;
    MockERC20 token;
    MockFlash flash;
    MockHandler poolHandler;

    function setUp() public {
        // deployments
        pool = new PoolManager(type(uint256).max);
        token = new MockERC20();
        flash = new MockFlash(pool);
        poolHandler = new MockHandler(pool);

        // initialize pool and donate token
        token.mint(address(poolHandler), 1 ether);
        poolHandler.initialize(address(token));
        poolHandler.initiateDonate(address(token));
    }

    function testVibecheck() public {
        assertTrue(true);
    }
}
