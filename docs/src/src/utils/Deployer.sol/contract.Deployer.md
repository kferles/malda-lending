# Deployer
[Git Source](https://github.com/malda-protocol/malda-lending/blob/acd5ab2b6c54b66703c366d922b6691b77a8c9fd/src\utils\Deployer.sol)


## State Variables
### admin

```solidity
address public admin;
```


### pendingAdmin

```solidity
address public pendingAdmin;
```


## Functions
### onlyAdmin


```solidity
modifier onlyAdmin();
```

### constructor


```solidity
constructor(address _admin);
```

### receive


```solidity
receive() external payable;
```

### setPendingAdmin


```solidity
function setPendingAdmin(address newAdmin) external onlyAdmin;
```

### saveEth


```solidity
function saveEth() external;
```

### setNewAdmin


```solidity
function setNewAdmin(address _addr) external;
```

### precompute


```solidity
function precompute(bytes32 salt) external view returns (address);
```

### create


```solidity
function create(bytes32 salt, bytes memory code) external payable onlyAdmin returns (address);
```

### acceptAdmin


```solidity
function acceptAdmin() external;
```

## Events
### AdminSet

```solidity
event AdminSet(address indexed _admin);
```

### PendingAdminSet

```solidity
event PendingAdminSet(address indexed _admin);
```

### AdminAccepted

```solidity
event AdminAccepted(address indexed _admin);
```

## Errors
### NotAuthorized

```solidity
error NotAuthorized(address admin, address sender);
```

