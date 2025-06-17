// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {DeployBase} from "script/deployers/DeployBase.sol";
import {VoluntaryRecovery} from "src/recovery/VoluntaryRecovery.sol";
import {Deployer} from "src/utils/Deployer.sol";

contract DeployVoluntaryRecovery is Script {
    function run(address owner) public returns (address) {
        Deployer deployer = Deployer(payable(0xc781BaD08968E324D1B91Be3cca30fAd86E7BF98));
        address usdc = address(0);

        uint256 key = vm.envUint("OWNER_PRIVATE_KEY");

        bytes32 salt = getSalt("VoluntaryRecoveryV1.0.0");

        console.log("Deploying VoluntaryRecovery");

        address created = deployer.precompute(salt);

        // Deploy only if not already deployed
        if (created.code.length == 0) {
            vm.startBroadcast(key);
            created =
                deployer.create(salt,  abi.encodePacked(type(VoluntaryRecovery).creationCode, abi.encode(usdc, owner)));
            vm.stopBroadcast();
            console.log("VoluntaryRecovery deployed at: %s", created);
        } else {
            console.log("Using existing VoluntaryRecovery at: %s", created);
        }

        return created;
    }

    function getSalt(string memory name) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(msg.sender, bytes(vm.envString("DEPLOY_SALT")), bytes(string.concat(name, "-v1")))
        );
    }
}