// SPDX-License-Identifier: GPL-2.0-only
pragma solidity 0.8.26;

import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "lib/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {IERC20Minimal} from "lib/v4-core/src/interfaces/external/IERC20Minimal.sol";
import {IHooks} from "lib/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "lib/v4-core/src/libraries/CurrencyDelta.sol";
import {TickMath} from "lib/v4-core/src/libraries/TickMath.sol";
import {BalanceDelta} from "lib/v4-core/src/types/BalanceDelta.sol";
import {MockERC20} from "test/mock/MockERC20.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {CurrencySettler} from "lib/v4-core/test/utils/CurrencySettler.sol";

contract MockHandler is IUnlockCallback {
    using CurrencySettler for Currency;

    error FailedExecution(bytes retdata);

    IPoolManager internal immutable pool;

    constructor(IPoolManager _pool) {
        pool = _pool;
    }

    // ---------------------------------------------------------------------------------------------
    // Called by the user.

    function initialize(address token0, address token1) public {
        pool.initialize(
            PoolKey({
                currency0: Currency.wrap(token0),
                currency1: Currency.wrap(token1),
                fee: 0,
                hooks: IHooks(address(0)),
                tickSpacing: 60
            }),
            TickMath.MIN_SQRT_PRICE,
            bytes("")
        );
    }

    function initiatemodifyLiquidity(address token0, address token1) public {
        pool.unlock(abi.encodeCall(this.modifyLiquidity, (token0, token1)));
    }

    // ---------------------------------------------------------------------------------------------
    // Called by the pool.

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        (bool success, bytes memory retdata) = address(this).call(data);
        if (!success) revert FailedExecution(retdata);
        return retdata;
    }

    // ---------------------------------------------------------------------------------------------
    // Called by this contract.

    function modifyLiquidity(address token0, address token1) public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 0,
            hooks: IHooks(address(0)),
            tickSpacing: 60
        });
        (BalanceDelta delta,  ) = pool.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 60,
                liquidityDelta: 100,
                salt: bytes32(0)
            }),
            bytes("")
        );

        if (delta.amount0() < 0) {
            MockERC20(token0).mint(address(this), uint256(int256(-delta.amount0())));
            key.currency0.settle(pool, address(this), uint256(int256(-delta.amount0())), false);
        }

        if (delta.amount1() < 0) {
            MockERC20(token1).mint(address(this), uint256(int256(-delta.amount1())));
            key.currency1.settle(pool, address(this), uint256(int256(-delta.amount1())), false);
        }
    }
}
