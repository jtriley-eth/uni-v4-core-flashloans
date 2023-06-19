// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.20;

import {ILockCallback} from "lib/v4-core/contracts/interfaces/callback/ILockCallback.sol";
import {IERC20Minimal} from "lib/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {Currency} from "lib/v4-core/contracts/libraries/CurrencyLibrary.sol";

/// @title Simple Flashloan (Uniswap V4)
/// @author jtriley.eth
/// @notice Abstract contract that can handle flashloans.
/// @dev `_handleFlashLoan(address)` must be implemented and at least the amount taken must be in
/// THIS contract by the end of its execution.
abstract contract SimpleFlash is ILockCallback {
    IPoolManager internal immutable pool;

    constructor(IPoolManager _pool) {
        pool = _pool;
    }

    /// @notice Initiates the flashloan execution.
    /// @dev This is the entry point. The `lock` must be acquired before lending.
    /// @param token The token to flashloan.
    function initiate(address token) public {
        pool.lock(abi.encode(token));
    }

    /// @notice Callback to handle the flashloan.
    /// @dev Takes full balance of token from pool via `take`, calls `_handleFlashloan`, and settles
    /// the flashloan via `settle`.
    /// @param data The encoded token address.
    /// @return retdata Arbitrary data (implicit return).
    function lockAcquired(uint256,bytes calldata data) public override returns (bytes memory retdata) {
        // decode the token from the lock data
        (address token) = abi.decode(data, (address));
        // get the full balance of the pool
        uint256 poolBalance = IERC20Minimal(token).balanceOf(address(pool));
        // take the full balance of the pool with `take`
        pool.take(Currency.wrap(token), address(this), poolBalance);
        // call the internal handler
        retdata = _handleFlashloan(token);
        // repay the flashloan
        IERC20Minimal(token).transfer(address(pool), poolBalance);
        // settle the balance after repayment with `settle`.
        pool.settle(Currency.wrap(token));
        // return empty bytes
        return new bytes(0);
    }

    /// @notice Handles Ether transfers.
    receive() external payable {}

    function _handleFlashloan(address token) internal virtual returns (bytes memory);
}
