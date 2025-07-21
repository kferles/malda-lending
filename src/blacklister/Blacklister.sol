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

// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

/*
 _____ _____ __    ____  _____ 
|     |  _  |  |  |    \|  _  |
| | | |     |  |__|  |  |     |
|_|_|_|__|__|_____|____/|__|__|   
*/

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRoles} from "src/interfaces/IRoles.sol";


contract Blacklister is OwnableUpgradeable {
    // ----------- STORAGE -----------
    mapping(address => bool) public isBlacklisted;
    address[] blacklistedAddresses;
    mapping(address => bool) public proposedForBlacklist;
    mapping(address => uint256) public blacklistProposalTimestamp;
    uint256 public proposalExpiryTime = 3 days;

    IRoles public rolesOperator;

    // ----------- EVENTS -----------
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);
    event BlacklistProposed(address indexed user);
    event BlacklistProposalExpiry(uint256 newVal);

    // ----------- ERRORS -----------
    error Blacklister_AlreadyBlacklisted();
    error Blacklister_NotBlacklisted();
    error Blacklister_AlreadyProposed();
    error Blacklister_NotProposed();
    error Blacklister_NotAllowed();
    error Blacklister_ProposalExpired();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address payable _owner, address _roles)
        external
        initializer
    {
        __Ownable_init(_owner);
        rolesOperator = IRoles(_roles);
    }

    // ----------- VIEW ------------
    function getBlacklistedAddresses() external view returns (address[] memory) {
        return blacklistedAddresses;
    }

    function isProposalExpired(address user) public view returns (bool) {
        if (!proposedForBlacklist[user]) return false;
        return block.timestamp > blacklistProposalTimestamp[user] + proposalExpiryTime;
    }

    
    // ----------- OWNER ------------
    function blacklist(address user) external onlyOwner {
        require(!isBlacklisted[user], Blacklister_AlreadyBlacklisted());
        isBlacklisted[user] = true;
        blacklistedAddresses.push(user);
        proposedForBlacklist[user] = false;
        blacklistProposalTimestamp[user] = 0;
        emit Blacklisted(user);
    }

    function unblacklist(address user) external onlyOwner {
        require(isBlacklisted[user], Blacklister_NotBlacklisted());
        isBlacklisted[user] = false;
        uint256 len = blacklistedAddresses.length;
        for (uint256 i; i < len; ++i) {
            if (blacklistedAddresses[i] == user) {
                blacklistedAddresses[i] = blacklistedAddresses[len - 1];
                blacklistedAddresses.pop();
                break;
            }
        }
        proposedForBlacklist[user] = false;
        blacklistProposalTimestamp[user] = 0;
        emit Unblacklisted(user);
    }

    function proposeToBlacklist(address user) external {
        if (!rolesOperator.isAllowedFor(msg.sender, rolesOperator.GUARDIAN_BLACKLIST())) revert Blacklister_NotAllowed();
        require(!isBlacklisted[user], Blacklister_AlreadyBlacklisted());
        require(!proposedForBlacklist[user], Blacklister_AlreadyProposed());
        blacklistProposalTimestamp[user] = block.timestamp;
        proposedForBlacklist[user] = true;
        emit BlacklistProposed(user);
    }

    function approveBlacklist(address user) external onlyOwner {
        require(proposedForBlacklist[user], Blacklister_NotProposed());
        require(!isBlacklisted[user], Blacklister_AlreadyBlacklisted());
        if (block.timestamp > blacklistProposalTimestamp[user] + proposalExpiryTime) {
            revert Blacklister_ProposalExpired();
        }

        proposedForBlacklist[user] = false;
        blacklistProposalTimestamp[user] = 0;
        isBlacklisted[user] = true;
        blacklistedAddresses.push(user);

        emit Blacklisted(user);
    }

    function setProposalExpiry(uint256 expiry) external onlyOwner {
        proposalExpiryTime = expiry;
        emit BlacklistProposalExpiry(expiry);
    }
}