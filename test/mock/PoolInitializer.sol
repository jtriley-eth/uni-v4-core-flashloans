// SPDX-License-Identifier: GPL-2.0-only
pragma solidity 0.8.20;

import {IPoolManager} from "lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {ILockCallback} from "lib/v4-core/contracts/interfaces/callback/ILockCallback.sol";
import {IHooks} from "lib/v4-core/contracts/interfaces/IHooks.sol";

import {CurrencyLibrary, Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {TickMath} from "lib/v4-core/contracts/libraries/TickMath.sol";
import {BalanceDelta} from "lib/v4-core/contracts/types/BalanceDelta.sol";
import {MockERC20} from "test/mock/MockERC20.sol";

contract PoolInitializer is ILockCallback {
    IPoolManager internal manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    function initialize(address token0, address token1) public {
      IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
          currency0: Currency.wrap(address(token0)),
          currency1: Currency.wrap(address(token1)),
          fee: 0,
          hooks: IHooks(address(0)),
          tickSpacing: 60
      });
        manager.initialize(
            key,
            TickMath.MIN_SQRT_RATIO
        );

        _modifyPosition(
            key,
            IPoolManager.ModifyPositionParams({
                tickLower: 0,
                tickUpper: 60,
                liquidityDelta: 100
            })
        );
    }

    function _modifyPosition(
        IPoolManager.PoolKey memory key,
        IPoolManager.ModifyPositionParams memory params
    ) internal {
        manager.lock(abi.encode(CallbackData(key, params)));
    }

    struct CallbackData {
        IPoolManager.PoolKey key;
        IPoolManager.ModifyPositionParams params;
    }

    function lockAcquired(
        uint256,
        bytes calldata rawData
    ) external returns (bytes memory) {
        CallbackData memory data = abi.decode(rawData, (CallbackData));

        BalanceDelta delta = manager.modifyPosition(data.key, data.params);

        address token0 = Currency.unwrap(data.key.currency0);
        address token1 = Currency.unwrap(data.key.currency1);

        if (delta.amount0() > 0) {
            MockERC20(token0).mint(address(manager), uint128(delta.amount0()));
            manager.settle(data.key.currency0);
        }
        if (delta.amount1() > 0) {
            MockERC20(token1).mint(address(manager), uint128(delta.amount1()));
            manager.settle(data.key.currency1);
        }
    }
}
