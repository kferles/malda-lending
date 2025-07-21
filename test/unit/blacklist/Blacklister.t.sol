// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Blacklister} from "src/blacklister/Blacklister.sol";
import {MockRoles} from "test/mocks/MockRoles.sol";

contract BlacklisterTest is Test {
    Blacklister blacklister;
    MockRoles roles;
    address owner = address(0xABCD);
    address guardian = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        roles = new MockRoles();
        Blacklister blacklisterImp = new Blacklister();
        bytes memory blacklisterInitData = abi.encodeWithSelector(Blacklister.initialize.selector, address(owner), address(roles));
        ERC1967Proxy blacklisterProxy = new ERC1967Proxy(address(blacklisterImp), blacklisterInitData);
        blacklister = Blacklister(address(blacklisterProxy));
        vm.label(address(blacklister), "Blacklister");
    }

    function testProposeToBlacklist() public {
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);
        assertTrue(blacklister.proposedForBlacklist(user));
    }

    function testProposeAlreadyBlacklistedReverts() public {
        vm.prank(owner);
        blacklister.blacklist(user);

        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        vm.expectRevert(Blacklister.Blacklister_AlreadyBlacklisted.selector);
        blacklister.proposeToBlacklist(user);
    }

    function testProposeAlreadyProposedReverts() public {
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);

        vm.prank(guardian);
        vm.expectRevert(Blacklister.Blacklister_AlreadyProposed.selector);
        blacklister.proposeToBlacklist(user);
    }

    function testProposeNotAllowedReverts() public {
        vm.prank(guardian);
        vm.expectRevert(Blacklister.Blacklister_NotAllowed.selector);
        blacklister.proposeToBlacklist(user);
    }

    function testBlacklistAndUnblacklist() public {
        vm.prank(owner);
        blacklister.blacklist(user);
        assertTrue(blacklister.isBlacklisted(user));

        vm.prank(owner);
        blacklister.unblacklist(user);
        assertFalse(blacklister.isBlacklisted(user));
    }

    function testBlacklistAlreadyBlacklistedReverts() public {
        vm.startPrank(owner);
        blacklister.blacklist(user);
        vm.expectRevert(Blacklister.Blacklister_AlreadyBlacklisted.selector);
        blacklister.blacklist(user);
        vm.stopPrank();
    }

    function testUnblacklistNotBlacklistedReverts() public {
        vm.prank(owner);
        vm.expectRevert(Blacklister.Blacklister_NotBlacklisted.selector);
        blacklister.unblacklist(user);
    }

    function testUnblacklistRemovesCorrectlyFromArray() public {
        address user2 = address(0xDEAD);
        vm.startPrank(owner);
        blacklister.blacklist(user);
        blacklister.blacklist(user2);
        blacklister.unblacklist(user);
        address[] memory list = blacklister.getBlacklistedAddresses();
        assertEq(list.length, 1);
        assertEq(list[0], user2);
        vm.stopPrank();
    }

    function testApproveBlacklist() public {
        vm.warp(block.timestamp + 1 days);
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);

        vm.warp(1 days);

        vm.prank(owner);
        blacklister.approveBlacklist(user);

        assertTrue(blacklister.isBlacklisted(user));
    }

    function testApproveBlacklistNotProposedReverts() public {
        vm.prank(owner);
        vm.expectRevert(Blacklister.Blacklister_NotProposed.selector);
        blacklister.approveBlacklist(user);
    }

    function testApproveAlreadyBlacklistedReverts() public {
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);

        vm.prank(owner);
        blacklister.blacklist(user);

        vm.expectRevert(Blacklister.Blacklister_NotProposed.selector);
        vm.prank(owner);
        blacklister.approveBlacklist(user);
    }


    function testApproveExpiredProposalReverts() public {
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);

        vm.warp(block.timestamp + 4 days); // > proposalExpiryTime

        vm.prank(owner);
        vm.expectRevert(Blacklister.Blacklister_ProposalExpired.selector);
        blacklister.approveBlacklist(user);
    }

    function testIsProposalExpiredLogic() public {
        roles.setAllowed(guardian, true);
        vm.prank(guardian);
        blacklister.proposeToBlacklist(user);

        assertFalse(blacklister.isProposalExpired(user));
        vm.warp(block.timestamp + 4 days);
        assertTrue(blacklister.isProposalExpired(user));
    }

    function testGetBlacklistedAddresses() public {
        vm.startPrank(owner);
        blacklister.blacklist(user);
        address[] memory list = blacklister.getBlacklistedAddresses();
        assertEq(list.length, 1);
        assertEq(list[0], user);
        vm.stopPrank();
    }
}
