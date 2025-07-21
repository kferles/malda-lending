# IOperatorData
[Git Source](https://github.com/malda-protocol/malda-lending/blob/076616677457911e7c8925ff7d5fe2dec2ca1497/src\interfaces\IOperator.sol)


## Structs
### Market

```solidity
struct Market {
    bool isListed;
    uint256 collateralFactorMantissa;
    mapping(address => bool) accountMembership;
    bool isMalded;
}
```

