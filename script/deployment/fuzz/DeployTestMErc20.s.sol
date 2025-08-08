// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {Script, console} from "forge-std/Script.sol";

import {Roles} from "src/Roles.sol";
import {Operator} from "src/Operator/Operator.sol";
import {RewardDistributor} from "src/rewards/RewardDistributor.sol";
import {JumpRateModelV4} from "src/interest/JumpRateModelV4.sol";
import {Blacklister} from "src/blacklister/Blacklister.sol";
import {mErc20Immutable} from "src/mToken/mErc20Immutable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

/// @title DeployTestMErc20
/// @notice Deployment script to spin up a minimal mErc20 market for fuzz tests
contract DeployTestMErc20 is Script {
    /// @notice Deploys supporting contracts, a mock underlying token and an mErc20Immutable market
    function run() external returns (address mToken, address underlying) {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        Roles roles = new Roles(address(this));

        RewardDistributor rewardsImpl = new RewardDistributor();
        bytes memory rewardsInit = abi.encodeWithSelector(RewardDistributor.initialize.selector, address(this));
        ERC1967Proxy rewardsProxy = new ERC1967Proxy(address(rewardsImpl), rewardsInit);
        RewardDistributor rewards = RewardDistributor(address(rewardsProxy));

        Blacklister blacklisterImpl = new Blacklister();
        bytes memory blacklisterInit = abi.encodeWithSelector(Blacklister.initialize.selector, address(this), address(roles));
        ERC1967Proxy blacklisterProxy = new ERC1967Proxy(address(blacklisterImpl), blacklisterInit);
        Blacklister blacklister = Blacklister(address(blacklisterProxy));

        Operator operatorImpl = new Operator();
        bytes memory operatorInit = abi.encodeWithSelector(
            Operator.initialize.selector,
            address(roles),
            address(blacklister),
            address(rewards),
            address(this)
        );
        ERC1967Proxy operatorProxy = new ERC1967Proxy(address(operatorImpl), operatorInit);
        Operator operator = Operator(address(operatorProxy));

        JumpRateModelV4 irm = new JumpRateModelV4(
            3_153_600, // blocks per year (approx for testing)
            792744799,
            1_981_000_000,
            251_900_000_000,
            400_000_000_000_000_000,
            address(this),
            "Test Interest Model"
        );

        ERC20Mock underlyingToken = new ERC20Mock("Mock Token", "MOCK", 18, address(this), address(0), 0);

        mErc20Immutable market = new mErc20Immutable(
            address(underlyingToken),
            address(operator),
            address(irm),
            1e18,
            "Mock mToken",
            "mMOCK",
            18,
            payable(address(this))
        );

        vm.stopBroadcast();

        console.log("Underlying token deployed at", address(underlyingToken));
        console.log("mErc20 market deployed at", address(market));

        mToken = address(market);
        underlying = address(underlyingToken);
    }
}

