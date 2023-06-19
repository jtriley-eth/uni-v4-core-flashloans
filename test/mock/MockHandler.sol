// SPDX-License-Identifier: GPL-2.0-only
pragma solidity 0.8.20;

import {IPoolManager} from "lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {ILockCallback} from "lib/v4-core/contracts/interfaces/callback/ILockCallback.sol";
import {IERC20Minimal} from "lib/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IHooks} from "lib/v4-core/contracts/interfaces/IHooks.sol";
import {Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {TickMath} from "lib/v4-core/contracts/libraries/TickMath.sol";
import {BalanceDelta} from "lib/v4-core/contracts/types/BalanceDelta.sol";
import {MockERC20} from "test/mock/MockERC20.sol";

contract MockHandler is ILockCallback {

    error FailedExecution(bytes retdata);

    IPoolManager internal immutable pool;

    constructor(IPoolManager _pool) {
        pool = _pool;
    }

    // ---------------------------------------------------------------------------------------------
    // Called by the user.

    function initialize(address token0, address token1) public {
        pool.initialize(
            IPoolManager.PoolKey({
                currency0: Currency.wrap(token0),
                currency1: Currency.wrap(token1),
                fee: 0,
                hooks: IHooks(address(0)),
                tickSpacing: 60
            }),
            TickMath.MIN_SQRT_RATIO
        );
    }

    function initiateModifyPosition(address token0, address token1) public {
        pool.lock(abi.encodeCall(this.modifyPosition, (token0, token1)));
    }

    // ---------------------------------------------------------------------------------------------
    // Called by the pool.

    function lockAcquired(uint256, bytes calldata data) public override returns (bytes memory) {
        (bool success, bytes memory retdata) = address(this).call(data);
        if (!success) revert FailedExecution(retdata);
        return retdata;
    }

    // ---------------------------------------------------------------------------------------------
    // Called by this contract.

    function modifyPosition(address token0, address token1) public {
        BalanceDelta delta = pool.modifyPosition(
            IPoolManager.PoolKey({
                currency0: Currency.wrap(token0),
                currency1: Currency.wrap(token1),
                fee: 0,
                hooks: IHooks(address(0)),
                tickSpacing: 60
            }),
            IPoolManager.ModifyPositionParams({
                tickLower: 0,
                tickUpper: 60,
                liquidityDelta: 100
            })
        );

        if (delta.amount0() > 0) {
            MockERC20(token0).mint(address(pool), uint256(int256(delta.amount0())));
            pool.settle(Currency.wrap(token0));
        }

        if (delta.amount1() > 0) {
            MockERC20(token1).mint(address(pool), uint256(int256(delta.amount1())));
            pool.settle(Currency.wrap(token1));
        }
    }
}
