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
    address[] public users;
    mapping(address => bool) public seen;
    address public owner;

    constructor(VoluntaryRecovery _vr, ERC20Mock _usdc, address _owner) {
        vr = _vr;
        usdc = _usdc;
        owner = _owner;
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function act(uint8 userIndex, uint96 rawAmount) public {
        uint256 SECP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        uint256 privateKey = uint256(userIndex) + 1_000_000;
        privateKey = privateKey % (SECP_ORDER - 1) + 1;

        address user = vm.addr(privateKey);
        uint256 amount = bound(uint256(rawAmount), 1e6, 1_000_000e6); // 1 USDC - 1,000,000 USDC

        if (!seen[user]) {
            seen[user] = true;
            users.push(user);

            address[] memory _users = new address[](1);
            uint256[] memory _amounts = new uint256[](1);
            _users[0] = user;
            _amounts[0] = amount;

            allocated[user] = amount;

            vm.prank(owner);
            vr.setAllocations(_users, _amounts);
            usdc.mint(address(vr), amount * 2);
        }

        if (!vr.claimed(user)) {
            bytes32 msgHash = keccak256(abi.encodePacked(
                "VoluntaryRecovery:", block.chainid, address(vr), user, allocated[user]
            ));
            bytes memory sig = sign(privateKey, msgHash);

            vm.prank(user);
            try vr.acceptDisclaimerAndClaim(sig) {
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
