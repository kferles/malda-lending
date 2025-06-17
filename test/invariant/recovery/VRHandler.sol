// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;


import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {VoluntaryRecovery} from "src/recovery/VoluntaryRecovery.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VRHandler is Test {
    VoluntaryRecovery public vr;
    ERC20Mock public usdc;

    mapping(address => uint256) public allocated;
    mapping(address => uint256) public claimedAmount;

    constructor(VoluntaryRecovery _vr, ERC20Mock _usdc) {
        vr = _vr;
        usdc = _usdc;
    }

    function act(uint256 privateKey, uint96 rawAmount) public {
        uint256 SECP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        privateKey = bound(privateKey, 1, SECP_ORDER - 1);

        address user = vm.addr(privateKey);
        uint256 amount = bound(uint256(rawAmount), 1e6, 1_000_000e6); 

        if (allocated[user] == 0) {
            address[] memory users = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            users[0] = user;
            amounts[0] = amount;

            allocated[user] = amount;
            vr.setAllocations(users, amounts);
            usdc.mint(address(vr), amount);
        }

        if (!vr.disclaimerAccepted(user)) {
            bytes32 msgHash = keccak256(abi.encodePacked("VoluntaryRecovery:", user, block.chainid, address(vr), allocated[user]));
            bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
            bytes memory sig = sign(privateKey, ethHash);

            vm.prank(user);
            try vr.acceptDisclaimer(sig) {} catch {}
        }

        if (!vr.claimed(user)) {
            vm.prank(user);
            try vr.claim() {
                claimedAmount[user] = allocated[user];
            } catch {}
        }
    }

        // ----- internal

    function sign(uint256 privKey, bytes32 messageHash) internal pure returns (bytes memory) {
        bytes32 ethSigned = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, ethSigned);
        return abi.encodePacked(r, s, v);
    }
}
