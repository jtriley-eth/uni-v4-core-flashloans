// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.20;

import {SimpleFlash, IPoolManager} from "src/SimpleFlash.sol";

contract MockFlash is SimpleFlash {
    event HandledFlashloan(address token);

    constructor(IPoolManager _pool) SimpleFlash(_pool) {}

    function _handleFlashloan(address token) internal override returns (bytes memory) {
        emit HandledFlashloan(token);
        return new bytes(0);
    }
}
