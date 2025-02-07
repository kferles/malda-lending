// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.28;

import {RewardDistributor} from "src/rewards/RewardDistributor.sol";

import {Script, console} from "forge-std/Script.sol";

contract SetOperatorInRewardDistributor is Script {
    function run(address operator, address rewardDistributor) public {
        console.log("Setting operator %s for reward distributor %s", operator, rewardDistributor);

        uint256 key = vm.envUint("OWNER_PRIVATE_KEY");

        vm.startBroadcast(key);
        RewardDistributor(rewardDistributor).setOperator(operator);
        vm.stopBroadcast();

        console.log("Operator set for reward distributor %s", rewardDistributor);
    }
}
