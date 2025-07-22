# OFTFeeDetail
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\interfaces\external\layerzero\v2\ILayerZeroOFT.sol)

*Struct representing OFT fee details.*

*Future proof mechanism to provide a standardized way to communicate fees to things like a UI.*


```solidity
struct OFTFeeDetail {
    int256 feeAmountLD;
    string description;
}
```

