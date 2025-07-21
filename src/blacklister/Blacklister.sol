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
import {IBlacklister} from "src/interfaces/IBlacklister.sol";


contract Blacklister is OwnableUpgradeable, IBlacklister {
    // ----------- STORAGE -----------
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public proposedForBlacklist;
    mapping(address => uint256) public blacklistProposalTimestamp;
    uint256 public proposalExpiryTime = 3 days;
    
    address[] private _blacklistedList;

    IRoles public rolesOperator;

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
        return _blacklistedList;
    }

    function isProposalExpired(address user) public view returns (bool) {
        if (!proposedForBlacklist[user]) return false;
        return block.timestamp > blacklistProposalTimestamp[user] + proposalExpiryTime;
    }

    
    // ----------- OWNER ------------
    function blacklist(address user) external override onlyOwner {
        if (isBlacklisted[user]) revert Blacklister_AlreadyBlacklisted();
        _resetProposal(user);
        _addToBlacklist(user);
    }

    function unblacklist(address user) external override onlyOwner {
        if (!isBlacklisted[user]) revert Blacklister_NotBlacklisted();
        isBlacklisted[user] = false;
        _removeFromBlacklistList(user);
        _resetProposal(user);
        emit Unblacklisted(user);
    }

    function approveBlacklist(address user) external override onlyOwner {
        if (!proposedForBlacklist[user]) revert Blacklister_NotProposed();
        if (isBlacklisted[user]) revert Blacklister_AlreadyBlacklisted();
        if (isProposalExpired(user)) revert Blacklister_ProposalExpired();
        _resetProposal(user);
        _addToBlacklist(user);
    }

    function setProposalExpiry(uint256 expiry) external onlyOwner {
        proposalExpiryTime = expiry;
        emit BlacklistProposalExpiry(expiry);
    }
    // ----------- GUARDIAN ------------
    function proposeToBlacklist(address user) external override {
        if (!rolesOperator.isAllowedFor(msg.sender, rolesOperator.GUARDIAN_BLACKLIST())) {
            revert Blacklister_NotAllowed();
        }
        if (isBlacklisted[user]) revert Blacklister_AlreadyBlacklisted();
        if (proposedForBlacklist[user]) revert Blacklister_AlreadyProposed();

        proposedForBlacklist[user] = true;
        blacklistProposalTimestamp[user] = block.timestamp;
        emit BlacklistProposed(user);
    }

   
    // ----------- INTERNAL ------------
    function _resetProposal(address user) internal {
        proposedForBlacklist[user] = false;
        blacklistProposalTimestamp[user] = 0;
    }

    function _addToBlacklist(address user) internal {
        isBlacklisted[user] = true;
        _blacklistedList.push(user);
        emit Blacklisted(user);
    }
    
    function _removeFromBlacklistList(address user) internal {
        uint256 len = _blacklistedList.length;
        for (uint256 i; i < len; ++i) {
            if (_blacklistedList[i] == user) {
                _blacklistedList[i] = _blacklistedList[len - 1];
                _blacklistedList.pop();
                break;
            }
        }
    }
}