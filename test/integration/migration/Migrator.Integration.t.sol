// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Base_Integration_Test} from "../Base_Integration_Test.t.sol";

import {Operator} from "src/Operator/Operator.sol";
import {Migrator} from "src/migration/Migrator.sol";
import {ZkVerifier} from "src/verifier/ZkVerifier.sol";
import {mErc20Host} from "src/mToken/host/mErc20Host.sol";
import {JumpRateModelV4} from "src/interest/JumpRateModelV4.sol";
import {RewardDistributor} from "src/rewards/RewardDistributor.sol";
import {Risc0VerifierMock} from "../../mocks/Risc0VerifierMock.sol";
import {OracleMock} from "../../mocks/OracleMock.sol";
import {ImToken, ImTokenOperationTypes} from "src/interfaces/ImToken.sol";

import {ImToken} from "src/interfaces/ImToken.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MigrationTests is Base_Integration_Test {

    address public constant COMPTROLLER = 0x1b4d3b0421dDc1eB216D230Bc01527422Fb93103;

    Migrator public migrator;
    Operator public operator;
    ZkVerifier public zkVerifier;
    RewardDistributor public rewards;
    JumpRateModelV4 public interestModel;
    Risc0VerifierMock public verifierMock;
    OracleMock public oracleOperator;

    address public constant USER_V1 = 0xCde13fF278bc484a09aDb69ea1eEd3cAf6Ea4E00;
    address public constant WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
    address public constant WETH_MARKET_V1 = 0xAd7f33984bed10518012013D4aB0458D37FEE6F3;
    address public constant MALDA_WETH_MARKET = 0xC7Bc6bD45Eb84D594f51cED3c5497E6812C7732f;
    address public constant MALDA_WETH_MARKET_OWNER = 0x91B945CbB063648C44271868a7A0c7BdFf64827D;

    function setUp() public override {
        super.setUp();

        vm.selectFork(lineaFork);

        migrator = new Migrator();

        RewardDistributor rewardsImpl = new RewardDistributor();
        bytes memory rewardsInitData = abi.encodeWithSelector(RewardDistributor.initialize.selector, address(this));
        ERC1967Proxy rewardsProxy = new ERC1967Proxy(address(rewardsImpl), rewardsInitData);
        rewards = RewardDistributor(address(rewardsProxy));
        vm.label(address(rewards), "RewardDistributor");

        Operator oprImp = new Operator();
        bytes memory operatorInitData =
            abi.encodeWithSelector(Operator.initialize.selector, address(roles), address(rewards), address(this));
        ERC1967Proxy operatorProxy = new ERC1967Proxy(address(oprImp), operatorInitData);
        operator = Operator(address(operatorProxy));
        vm.label(address(operator), "Operator");

        rewards.setOperator(address(operator));

        verifierMock = new Risc0VerifierMock();
        vm.label(address(verifierMock), "verifierMock");

        zkVerifier = new ZkVerifier(address(this), "0x123", address(verifierMock));
        vm.label(address(zkVerifier), "ZkVerifier contract");

        interestModel = new JumpRateModelV4(
            31536000, 0, 1981861998, 43283866057, 800000000000000000, address(this), "InterestModel"
        );
        vm.label(address(interestModel), "InterestModel");

        oracleOperator = new OracleMock(address(this));
        vm.label(address(oracleOperator), "oracleOperator");

        // **** SETUP ****
        rewards.setOperator(address(operator));
        operator.setPriceOracle(address(oracleOperator));

    }

    function testCollectAllMendiPositions() external {
        vm.prank(USER_V1);
        Migrator.Position[] memory positions = migrator.getAllPositions(USER_V1);

        assertEq(positions.length, 1);
        assertGt(positions[0].collateralUnderlyingAmount, 0.01 ether);    
        assertEq(positions[0].maldaMarket, address(MALDA_WETH_MARKET));
    }

    function testGetAllCollateralMarkets() external view {
        address[] memory positions = migrator.getAllCollateralMarkets(USER_V1);
        assertEq(positions.length, 1);
        assertEq(positions[0], WETH_MARKET_V1);
    }

    //The following will revert until a new market is deployed. 
    /**
    function testMigrateAllPositions() external {
        vm.startPrank(MALDA_WETH_MARKET_OWNER);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.AmountIn, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.AmountInHere, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.AmountOut, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.AmountOutHere, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Seize, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Transfer, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Mint, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Borrow, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Repay, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Redeem, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Liquidate, false);
        Operator(migrator.MALDA_OPERATOR()).setPaused(MALDA_WETH_MARKET, ImTokenOperationTypes.OperationType.Rebalancing, false);
        mErc20Host(MALDA_WETH_MARKET).setMigrator(address(migrator));
        vm.stopPrank();
     
        uint256 mendiV1Collateral = ImToken(MALDA_WETH_MARKET).balanceOfUnderlying(USER_V1);

        deal(WETH, MALDA_WETH_MARKET, 1 ether);
        vm.startPrank(USER_V1);
        IERC20(WETH_MARKET_V1).approve(address(migrator), type(uint256).max);
        migrator.migrateAllPositions();
        IERC20(MALDA_WETH_MARKET).approve(address(migrator), 0);
        vm.stopPrank();

        uint256 collateralAmount = ImToken(MALDA_WETH_MARKET).balanceOfUnderlying(address(this));

        assertApproxEqAbs(mendiV1Collateral, collateralAmount, 0.1e18);
    }
    */

}