# CommonLib
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\libraries\CommonLib.sol)


## Functions
### checkLengthMatch


```solidity
function checkLengthMatch(uint256 l1, uint256 l2) internal pure;
```

### checkLengthMatch


```solidity
function checkLengthMatch(uint256 l1, uint256 l2, uint256 l3) internal pure;
```

### computeSum


```solidity
function computeSum(uint256[] calldata values) internal pure returns (uint256 sum);
```

### checkHostToExtension


```solidity
function checkHostToExtension(
    uint256 amount,
    uint32 dstChainId,
    uint256 msgValue,
    mapping(uint32 => bool) storage allowedChains,
    IGasFeesHelper gasHelper
) internal view;
```

## Errors
### CommonLib_LengthMismatch

```solidity
error CommonLib_LengthMismatch();
```

### AmountNotValid

```solidity
error AmountNotValid();
```

### ChainNotValid

```solidity
error ChainNotValid();
```

### NotEnoughGasFee

```solidity
error NotEnoughGasFee();
```

