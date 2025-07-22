# DefaultGasHelper
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\oracles\gas\DefaultGasHelper.sol)

**Inherits:**
Ownable


## State Variables
### gasFees

```solidity
mapping(uint32 => uint256) public gasFees;
```


## Functions
### constructor


```solidity
constructor(address _owner) Ownable(_owner);
```

### setGasFee

Sets the gas fee


```solidity
function setGasFee(uint32 dstChainId, uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dstChainId`|`uint32`|the destination chain id|
|`amount`|`uint256`|the gas fee amount|


## Events
### GasFeeUpdated

```solidity
event GasFeeUpdated(uint32 indexed dstChainid, uint256 amount);
```

