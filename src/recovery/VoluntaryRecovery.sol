// Copyright (c) 2025 Merge Layers Inc.
//
// This source code is licensed under the Business Source License 1.1
// (the "License"); you may not use this file except in compliance with the
// License. You may obtain a copy of the License at
//
//     https://github.com/malda-protocol/malda-lending/blob/main/LICENSE-BSL
//
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.28;

/*
 _____ _____ __    ____  _____ 
|     |  _  |  |  |    \|  _  |
| | | |     |  |__|  |  |     |
|_|_|_|__|__|_____|____/|__|__|   
*/


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VoluntaryRecovery is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // ----------- STORAGE ------------
    IERC20 public immutable usdc;
    uint256 public immutable startTime;

    mapping(address => uint256) public allocated;
    mapping(address => bool) public claimed;
    mapping(address => bool) public disclaimerAccepted;

    uint256 public constant WITHDRAW_TIMELOCK = 48 days;

    // ----------- EVENTS ------------
    event AllocationSet(address indexed user, uint256 amount);
    event DisclaimerAccepted(address indexed user);
    event Claimed(address indexed user, uint256 amount);
    event WithdrawnUnclaimed(address indexed to, uint256 amount);

    // ----------- ERRORS ------------
    error VoluntaryRecovery_InvalidAddress();
    error VoluntaryRecovery_LengthMismatch();
    error VoluntaryRecovery_NoAllocation();
    error VoluntaryRecovery_InvalidSignature();
    error VoluntaryRecovery_AlreadyClaimed();
    error VoluntaryRecovery_DisclaimerNotAccepted();
    error VoluntaryRecovery_Timelocked();

    constructor(address _usdc, address _owner) Ownable(_owner) {
        require(_usdc != address(0), VoluntaryRecovery_InvalidAddress());
        usdc = IERC20(_usdc);
        startTime = block.timestamp;
    }

    // ----------- OWNER ------------
    /// @notice Admin sets allocations
    function setAllocations(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, VoluntaryRecovery_LengthMismatch());
        for (uint256 i; i < users.length; ++i) {
            allocated[users[i]] = amounts[i];
            emit AllocationSet(users[i], amounts[i]);
        }
    }
    
    function withdrawUnclaimed(address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= startTime + WITHDRAW_TIMELOCK, VoluntaryRecovery_Timelocked());
        usdc.safeTransfer(to, amount);
        emit WithdrawnUnclaimed(to, amount);
    }


    // ----------- PUBLIC ------------
    function acceptDisclaimerAndClaim(bytes calldata signature) external nonReentrant {
        address user = msg.sender;

        uint256 amount = allocated[user];
        require(amount > 0, VoluntaryRecovery_NoAllocation());

        require(!claimed[user], VoluntaryRecovery_AlreadyClaimed());

        // verify disclaimer signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            "VoluntaryRecovery:", block.chainid, address(this), user, amount
        ));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        require(ethSignedMessageHash.recover(signature) == user, VoluntaryRecovery_InvalidSignature());

        // mark disclaimer accepted and claimed
        disclaimerAccepted[user] = true;
        claimed[user] = true;

        // transfer funds
        usdc.safeTransfer(user, amount);

        emit DisclaimerAccepted(user);
        emit Claimed(user, amount);
    }
}