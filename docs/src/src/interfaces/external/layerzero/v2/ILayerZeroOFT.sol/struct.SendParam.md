# SendParam
[Git Source](https://github.com/malda-protocol/malda-lending/blob/076616677457911e7c8925ff7d5fe2dec2ca1497/src\interfaces\external\layerzero\v2\ILayerZeroOFT.sol)

*Struct representing token parameters for the OFT send() operation.*


```solidity
struct SendParam {
    uint32 dstEid;
    bytes32 to;
    uint256 amountLD;
    uint256 minAmountLD;
    bytes extraOptions;
    bytes composeMsg;
    bytes oftCmd;
}
```

