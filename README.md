# Uniswap V4 Flash Loan Template

Simple flashloan example for the Uniswap V4 singleton.

All pools are contained in the same contract and there is no flash fee, making it a suitable flash
lender.

## Implementation

The abstract implementation is relatively simplified and not gas optimized for the sake of
readability.

The function that must be implemented is as follows:

```solidity
function _handleFlashloan(address token) internal override returns (bytes memory) {
    // ...
}
```

Where `token` is the ERC20 (or Ether if the address is zero) can be handled.

The returned bytes of the function has no restrictions, it may be arbitrary data, but it will be
propagated back up from the `PoolManager`'s `lock` function.

The flashloan contract MUST contain at least the balance of the `token` at the start of the internal
function call. Taking and settling the flashloan is abstracted.

To start the execution, call `initiate(address token)`.

## Security Considerations

This DOES NOT implement authorization guards. While the lack of a flash fee removes the griefing
vulnerability of bleeding fees from unauthorized parties, if the contract holds a nonzero token or
ether balance at the end of the transaction, implementors must perform authorization checks to
avoid exploitation.
