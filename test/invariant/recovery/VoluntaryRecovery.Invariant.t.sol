// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;


import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {VoluntaryRecovery} from "src/recovery/VoluntaryRecovery.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {VRHandler} from "test/invariant/recovery/VRHandler.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract InvariantVoluntaryRecoveryTest is Test {
    VoluntaryRecovery public vr;
    ERC20Mock public usdc;
    VRHandler public handler;

    function setUp() public {
        usdc = new ERC20Mock("USDC","USDC", 6, address(this), address(0), 1e18);
        vr = new VoluntaryRecovery(address(usdc), address(this));
        handler = new VRHandler(vr, usdc);

        vm.label(address(vr), "VoluntaryRecovery");
        vm.label(address(usdc), "USDC");

        targetContract(address(handler));
    }

    function invariant_NoDoubleClaims() public view {
        for (uint160 i = 1; i < 100; i++) {
            address user = address(i);
            if (vr.claimed(user)) {
                assertTrue(vr.disclaimerAccepted(user));
            }
        }
    }

    function invariant_USDCNotOverWithdrawn() public view {
        uint256 totalAllocated;
        uint256 totalClaimed;

        for (uint160 i = 1; i < 100; i++) {
            address user = address(i);
            totalAllocated += handler.allocated(user);
            totalClaimed += handler.claimedAmount(user);
        }

        uint256 actualClaimable = usdc.balanceOf(address(vr));
        assertLe(totalClaimed, totalAllocated);
        assertEq(totalClaimed + actualClaimable, totalAllocated);
    }

    function invariant_TokenSupplyMatchesAccounting() public view {
        uint256 totalMinted = usdc.totalSupply();
        uint256 claimed;
        uint256 remaining;

        for (uint160 i = 1; i < 100; i++) {
            claimed += handler.claimedAmount(address(i));
            remaining += handler.allocated(address(i)) - handler.claimedAmount(address(i));
        }

        uint256 inContract = usdc.balanceOf(address(vr));
        assertEq(claimed + inContract, totalMinted);
    }

    function invariant_WithdrawUnclaimedRespectsTimelock() public {
        if (block.timestamp < vr.startTime() + 48 days) {
            vm.expectRevert();
            vr.withdrawUnclaimed(address(this), 1);
        }
    }



}
