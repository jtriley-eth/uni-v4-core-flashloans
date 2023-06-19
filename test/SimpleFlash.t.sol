// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {IPoolManager, PoolManager, IHooks} from "lib/v4-core/contracts/PoolManager.sol";
import {Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {MockERC20} from "test/mock/MockERC20.sol";
import {MockFlash} from "test/mock/MockFlash.sol";
import {MockHandler, PoolInitializer} from "test/mock/MockHandler.sol";
import {PoolModifyPositionTest} from "test/mock/PoolModifyPositionTest.sol";

contract SimpleFlashTest is Test {
    PoolManager pool;
    MockERC20 token0;
    MockERC20 token1;
    MockFlash flash;
    MockHandler poolHandler;

    function setUp() public {
        // deployments
        pool = new PoolManager(type(uint256).max);
        MockERC20 tokenA = new MockERC20();
        MockERC20 tokenB = new MockERC20();
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        flash = new MockFlash(pool);
        poolHandler = new MockHandler(pool);

        PoolInitializer initializer = new PoolInitializer(pool);
        initializer.initialize(address(token0), address(token1));
    }

    function testVibecheck() public {
        flash.initiate(address(token0));
    }
}
