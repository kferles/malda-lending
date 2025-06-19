// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {VoluntaryRecovery} from "src/recovery/VoluntaryRecovery.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VoluntaryRecoveryTest is Test {
    VoluntaryRecovery vr;
    ERC20Mock usdc;

    address owner = address(this);
    address user1;
    address user2;

    uint256 privateKey1;
    uint256 privateKey2;

    function setUp() public {
        usdc = new ERC20Mock("USDC", "USDC", 6, address(this), address(0), 1e18);
        vr = new VoluntaryRecovery(address(usdc), address(this));

        (user1, privateKey1) = makeAddrAndKey("user1");
        (user2, privateKey2) = makeAddrAndKey("user2");

        usdc.mint(address(vr), 1_000_000e6);
    }

    function testSetAllocations() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100e6;
        amounts[1] = 200e6;

        vr.setAllocations(users, amounts);

        assertEq(vr.allocated(user1), 100e6);
        assertEq(vr.allocated(user2), 200e6);
    }

    function testAcceptDisclaimerAndClaim() public {
        address[] memory users = new address[](1);
        users[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 150e6;
        vr.setAllocations(users, amounts);

        bytes32 messageHash = keccak256(abi.encodePacked("VoluntaryRecovery:", block.chainid, address(vr), user1, uint256(150e6)));
        bytes memory sig = sign(privateKey1, messageHash);

        vm.prank(user1);
        vr.acceptDisclaimerAndClaim(sig);

        assertTrue(vr.disclaimerAccepted(user1));
        assertTrue(vr.claimed(user1));
        assertEq(usdc.balanceOf(user1), 150e6);
    }

    function testCannotAcceptInvalidSignature() public {
        address[] memory users = new address[](1);
        users[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 300e6;
        vr.setAllocations(users, amounts);

        bytes32 wrongHash = keccak256(abi.encodePacked("WRONG:", user1, uint256(300e6)));
        bytes memory badSig = sign(privateKey1, wrongHash);

        vm.prank(user1);
        vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_InvalidSignature.selector);
        vr.acceptDisclaimerAndClaim(badSig);
    }

    function testClaimFailsIfAlreadyClaimed() public {
        testAcceptDisclaimerAndClaim();

        vm.prank(user1);
        vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_AlreadyClaimed.selector);
        vr.acceptDisclaimerAndClaim(sign(privateKey1, keccak256(abi.encodePacked("VoluntaryRecovery:", block.chainid, address(vr), user1, uint256(150e6)))));
    }

    function testWithdrawUnclaimedFailsBeforeTimelock() public {
        vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_Timelocked.selector);
        vr.withdrawUnclaimed(owner, 100e6);
    }

    function testWithdrawUnclaimedWorksAfterTimelock() public {
        vm.warp(block.timestamp + 48 days + 1);
        uint256 balanceBefore = usdc.balanceOf(owner);
        vr.withdrawUnclaimed(owner, 500e6);
        uint256 balanceAfter = usdc.balanceOf(owner);
        assertEq(balanceAfter - balanceBefore, 500e6);
    }

    function testAcceptFailsWithoutAllocation() public {
        bytes32 msgHash = keccak256(abi.encodePacked("VoluntaryRecovery:", block.chainid, address(vr), user1, uint256(0)));
        bytes memory sig = sign(privateKey1, msgHash);

        vm.prank(user1);
        vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_NoAllocation.selector);
        vr.acceptDisclaimerAndClaim(sig);
    }

    function testFuzz_AcceptDisclaimerAndClaim(uint256 userPrivateKey, uint96 rawAmount) public {
        userPrivateKey = bound(userPrivateKey, 1, type(uint256).max - 1);
        uint256 SECP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        userPrivateKey = bound(userPrivateKey, 1, SECP_ORDER - 1);
        address user = vm.addr(userPrivateKey);
        vm.assume(user != address(0));
        vm.assume(user != owner);
        uint256 amount = uint256(rawAmount) % 1_000_000e6;
        bytes32 msgHash;
        bytes memory sig;

        if (amount == 0) {
            msgHash = keccak256(abi.encodePacked("VoluntaryRecovery:", block.chainid, address(vr), user, uint256(0)));
            sig = sign(userPrivateKey, msgHash);

            vm.prank(user);
            vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_NoAllocation.selector);
            vr.acceptDisclaimerAndClaim(sig);
            return;
        }

        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        users[0] = user;
        amounts[0] = amount;
        vr.setAllocations(users, amounts);

        msgHash = keccak256(abi.encodePacked("VoluntaryRecovery:", block.chainid, address(vr), user, amount));
        sig = sign(userPrivateKey, msgHash);

        vm.prank(user);
        vr.acceptDisclaimerAndClaim(sig);
        assertTrue(vr.disclaimerAccepted(user));
        assertTrue(vr.claimed(user));
        assertEq(usdc.balanceOf(user), amount);

        vm.prank(user);
        vm.expectRevert(VoluntaryRecovery.VoluntaryRecovery_AlreadyClaimed.selector);
        vr.acceptDisclaimerAndClaim(sig);
    }

    // ----- internal

    function sign(uint256 privKey, bytes32 messageHash) internal pure returns (bytes memory) {
        bytes32 ethSigned = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, ethSigned);
        return abi.encodePacked(r, s, v);
    }
}
