# IConnext
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\interfaces\external\connext\IConnext.sol)


## Functions
### xcall


```solidity
function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
) external payable returns (bytes32);
```

### xcall


```solidity
function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
) external returns (bytes32);
```

### xcallIntoLocal


```solidity
function xcallIntoLocal(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
) external payable returns (bytes32);
```

### domain


```solidity
function domain() external view returns (uint256);
```

