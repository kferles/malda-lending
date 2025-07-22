// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {Counter} from "src/Counter.sol";
import {Deployer} from "src/utils/Deployer.sol";
import {Script, console} from "forge-std/Script.sol";

contract CounterCreate3Script is Script {
    Deployer deployer;

    function setUp() public {
        deployer = Deployer(payable(0xCde13fF278bc484a09aDb69ea1eEd3cAf6Ea4E00));
    }

    function run() public {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, bytes(vm.envString("DEPLOY_SALT"))));

        address created = deployer.create(salt, type(Counter).creationCode);
        console.log(created);

        vm.stopBroadcast();
    }
}
