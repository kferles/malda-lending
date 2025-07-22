# IFeeAdapter
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\interfaces\external\everclear\IFeeAdapter.sol)


## Functions
### newIntent


```solidity
function newIntent(
    uint32[] memory _destinations,
    bytes32 _receiver,
    address _inputAsset,
    bytes32 _outputAsset,
    uint256 _amount,
    uint24 _maxFee,
    uint48 _ttl,
    bytes calldata _data,
    FeeParams calldata _feeParams
) external payable returns (bytes32 _intentId, Intent memory _intent);
```

## Structs
### Intent

```solidity
struct Intent {
    bytes32 initiator;
    bytes32 receiver;
    bytes32 inputAsset;
    bytes32 outputAsset;
    uint24 maxFee;
    uint32 origin;
    uint64 nonce;
    uint48 timestamp;
    uint48 ttl;
    uint256 amount;
    uint32[] destinations;
    bytes data;
}
```

### FeeParams

```solidity
struct FeeParams {
    uint256 fee;
    uint256 deadline;
    bytes sig;
}
```

