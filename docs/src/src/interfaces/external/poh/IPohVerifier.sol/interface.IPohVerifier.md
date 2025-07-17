# IPohVerifier
[Git Source](https://github.com/malda-protocol/malda-lending/blob/01abcfb9040cf303f2a5fc706b3c3af752e0b27a/src\interfaces\external\poh\IPohVerifier.sol)


## Functions
### verify

Check if the provided signature has been signed by signer

*human is supposed to be a POH address, this is what is being signed by the POH API*


```solidity
function verify(bytes memory signature, address human) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature to check|
|`human`|`address`|the address for which the signature has been crafted|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the signature was made by signer, false otherwise|


### getSigner

Returns the signer's address


```solidity
function getSigner() external view returns (address);
```

