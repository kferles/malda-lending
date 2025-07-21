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
//
// This file contains code derived from or inspired by Compound V2,
// originally licensed under the BSD 3-Clause License. See LICENSE-COMPOUND-V2
// for original license terms and attributions.

// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

/*
 _____ _____ __    ____  _____ 
|     |  _  |  |  |    \|  _  |
| | | |     |  |__|  |  |     |
|_|_|_|__|__|_____|____/|__|__|   
*/

interface IBlacklister {
    // ----------- EVENTS -----------
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);
    event BlacklistProposed(address indexed user);
    event BlacklistProposalExpiry(uint256 newVal);

    // ----------- VIEW FUNCTIONS -----------
    /// @notice Returns the list of currently blacklisted addresses.
    function getBlacklistedAddresses() external view returns (address[] memory);

    /// @notice Returns whether a user has a blacklist proposal that has expired.
    function isProposalExpired(address user) external view returns (bool);

    /// @notice Returns whether a user is currently blacklisted.
    function isBlacklisted(address user) external view returns (bool);

    /// @notice Returns whether a user has been proposed for blacklisting.
    function proposedForBlacklist(address user) external view returns (bool);

    /// @notice Returns the timestamp of a blacklist proposal for a user.
    function blacklistProposalTimestamp(address user) external view returns (uint256);

    /// @notice Returns the current proposal expiry time.
    function proposalExpiryTime() external view returns (uint256);

    // ----------- OWNER ACTIONS -----------
    /// @notice Blacklists a user immediately (onlyOwner).
    function blacklist(address user) external;

    /// @notice Removes a user from the blacklist (onlyOwner).
    function unblacklist(address user) external;

    /// @notice Approves a blacklist proposal if it's still valid (onlyOwner).
    function approveBlacklist(address user) external;

    /// @notice Sets a new expiry time for blacklist proposals (onlyOwner).
    function setProposalExpiry(uint256 expiry) external;

    // ----------- GUARDIAN ACTION -----------
    /// @notice Proposes a user to be blacklisted (only allowed guardian).
    function proposeToBlacklist(address user) external;
}