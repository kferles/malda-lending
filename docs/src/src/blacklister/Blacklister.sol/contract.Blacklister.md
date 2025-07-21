# Blacklister
[Git Source](https://github.com/malda-protocol/malda-lending/blob/076616677457911e7c8925ff7d5fe2dec2ca1497/src\blacklister\Blacklister.sol)

**Inherits:**
OwnableUpgradeable


## State Variables
### isBlacklisted

```solidity
mapping(address => bool) public isBlacklisted;
```


### blacklistedAddresses

```solidity
address[] blacklistedAddresses;
```


### proposedForBlacklist

```solidity
mapping(address => bool) public proposedForBlacklist;
```


### blacklistProposalTimestamp

```solidity
mapping(address => uint256) public blacklistProposalTimestamp;
```


### proposalExpiryTime

```solidity
uint256 public proposalExpiryTime = 3 days;
```


### rolesOperator

```solidity
IRoles public rolesOperator;
```


## Functions
### constructor

**Note:**
oz-upgrades-unsafe-allow: constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address payable _owner, address _roles) external initializer;
```

### getBlacklistedAddresses


```solidity
function getBlacklistedAddresses() external view returns (address[] memory);
```

### isProposalExpired


```solidity
function isProposalExpired(address user) public view returns (bool);
```

### blacklist


```solidity
function blacklist(address user) external onlyOwner;
```

### unblacklist


```solidity
function unblacklist(address user) external onlyOwner;
```

### proposeToBlacklist


```solidity
function proposeToBlacklist(address user) external;
```

### approveBlacklist


```solidity
function approveBlacklist(address user) external onlyOwner;
```

### setProposalExpiry


```solidity
function setProposalExpiry(uint256 expiry) external onlyOwner;
```

## Events
### Blacklisted

```solidity
event Blacklisted(address indexed user);
```

### Unblacklisted

```solidity
event Unblacklisted(address indexed user);
```

### BlacklistProposed

```solidity
event BlacklistProposed(address indexed user);
```

### BlacklistProposalExpiry

```solidity
event BlacklistProposalExpiry(uint256 newVal);
```

## Errors
### Blacklister_AlreadyBlacklisted

```solidity
error Blacklister_AlreadyBlacklisted();
```

### Blacklister_NotBlacklisted

```solidity
error Blacklister_NotBlacklisted();
```

### Blacklister_AlreadyProposed

```solidity
error Blacklister_AlreadyProposed();
```

### Blacklister_NotProposed

```solidity
error Blacklister_NotProposed();
```

### Blacklister_NotAllowed

```solidity
error Blacklister_NotAllowed();
```

### Blacklister_ProposalExpired

```solidity
error Blacklister_ProposalExpired();
```

