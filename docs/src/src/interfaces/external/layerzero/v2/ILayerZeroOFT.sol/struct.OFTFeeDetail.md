# OFTFeeDetail
[Git Source](https://github.com/malda-protocol/malda-lending/blob/076616677457911e7c8925ff7d5fe2dec2ca1497/src\interfaces\external\layerzero\v2\ILayerZeroOFT.sol)

*Struct representing OFT fee details.*

*Future proof mechanism to provide a standardized way to communicate fees to things like a UI.*


```solidity
struct OFTFeeDetail {
    int256 feeAmountLD;
    string description;
}
```

