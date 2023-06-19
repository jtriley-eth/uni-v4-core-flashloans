// SPDX-License-Identifier: GPL-2.0-only
pragma solidity 0.8.20;

import {IPoolManager} from "lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {ILockCallback} from "lib/v4-core/contracts/interfaces/callback/ILockCallback.sol";
import {IERC20Minimal} from "lib/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IHooks} from "lib/v4-core/contracts/interfaces/IHooks.sol";
import {Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {TickMath} from "lib/v4-core/contracts/libraries/TickMath.sol";

contract MockHandler is ILockCallback {

    error FailedExecution(bytes retdata);

    IPoolManager internal immutable pool;

    constructor(IPoolManager _pool) {
        pool = _pool;
    }

    // ---------------------------------------------------------------------------------------------
    // Called by the user.

    function initialize(address token) public {
        pool.initialize(
            IPoolManager.PoolKey({
                currency0: Currency.wrap(address(0)),
                currency1: Currency.wrap(token),
                fee: 0,
                hooks: IHooks(address(0)),
                tickSpacing: 60
            }),
            TickMath.MIN_SQRT_RATIO
        );
    }

    function initiateDonate(address token) public {
        pool.lock(abi.encodeCall(this.donate, (token)));
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

    function donate(address token) public {
        Currency currency = Currency.wrap(token);
        pool.donate(
            IPoolManager.PoolKey({
                currency0: Currency.wrap(address(0)),
                currency1: Currency.wrap(token),
                fee: 0,
                hooks: IHooks(address(0)),
                tickSpacing: 60
            }),
            0,
            IERC20Minimal(token).balanceOf(address(this))
        );
    }
}
