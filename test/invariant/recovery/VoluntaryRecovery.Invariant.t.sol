// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {VoluntaryRecovery} from "src/recovery/VoluntaryRecovery.sol";
import {VRHandler} from "test/invariant/recovery/VRHandler.sol";

contract InvariantVoluntaryRecoveryTest is StdInvariant, Test {
    VoluntaryRecovery public vr;
    ERC20Mock public usdc;
    VRHandler public handler;

    function setUp() public {
        usdc = new ERC20Mock("USDC", "USDC", 6, address(this), address(0), 1e18);
        vr = new VoluntaryRecovery(address(usdc), address(this));
        handler = new VRHandler(vr, usdc, address(this));
        vm.label(address(vr), "VoluntaryRecovery");
        vm.label(address(usdc), "USDC");

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = handler.act.selector;
        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));
    }

    function invariant_NoClaimWithoutDisclaimerSigned() public {
        address[] memory users = handler.getUsers();

        for (uint160 i; i < users.length; ++i) {
            address user = users[i];
            if (vr.claimed(user)) {
                assertTrue(vr.disclaimerAccepted(user));
            }
        }
    }

    function invariant_TokenSupplyMatchesAccounting() public view {
        uint256 totalMinted = usdc.totalSupply();
        uint256 claimed;
        uint256 remaining;

        address[] memory users = handler.getUsers();
        for (uint160 i; i < users.length; ++i) {
            address user = users[i];
            claimed += handler.claimedAmount(user);
            remaining += handler.allocated(user) - handler.claimedAmount(user);
        }

        uint256 inContract = usdc.balanceOf(address(vr));
        assertEq(claimed + inContract, totalMinted);
    }

    function invariant_WithdrawUnclaimedFailsBeforeTimelock() public {
        vm.warp(vr.startTime() + 47 days); 
        vm.expectRevert();
        vr.withdrawUnclaimed(address(this), 1);
    }

    function invariant_WithdrawUnclaimedSucceedsAfterTimelock() public {
        vm.warp(vr.startTime() + 49 days); 
        vr.withdrawUnclaimed(address(this), 0);
    }
}