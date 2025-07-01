// SPDX-License-Identifier: BSL-1.1
pragma solidity =0.8.28;

import {IRebalancer, IRebalanceMarket} from "src/interfaces/IRebalancer.sol";
import {IFeeAdapter} from "src/interfaces/external/everclear/IFeeAdapter.sol";
import {Rebalancer_Unit_Shared} from "../shared/Rebalancer_Unit_Shared.t.sol";

import "forge-std/console2.sol";

contract Rebalancer_methods is Rebalancer_Unit_Shared {
    function setUp() public override {
        super.setUp();

        roles.allowFor(address(this), roles.GUARDIAN_BRIDGE(), true);
        rebalancer.setMaxTransferSize(0, address(weth), type(uint256).max);
        rebalancer.setMaxTransferSize(1, address(weth), type(uint256).max);
        roles.allowFor(address(this), roles.GUARDIAN_BRIDGE(), false);
    }

    modifier givenSenderDoesNotHaveGUARDIAN_BRIDGERole() {
        //does nothing; for readability only
        _;
    }

    function test_evercleardecoding() pure external {
        bytes memory data = hex"0000000000000000000000000000000000000000000000000000000000000140000000000000000000000000b819a871d20913839c37f316dc914b0570bfc0ee000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000b2c639c533813f4aa9d7837caf62653d097ff850000000000000000000000000000000000000000000000000000000000072d0300000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008153d0000000000000000000000000000000000000000000000000000000068491f680000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000004131bf6ef2678c118d003bcb3dd871374010823884615ce870cedb264411c66d3e7b72daa0cb2a14169be0c8af08b5191f810eab370f3577c0aafc337b817a72c81b00000000000000000000000000000000000000000000000000000000000000";
        
        (
            uint32[] memory _destinations,
            bytes32 _receiver,
            address _inputAsset,
            bytes32 _outputAsset,
            uint256 _amount,
            uint24 _maxFee,
            uint48 _ttl,
            bytes memory _data,
            IFeeAdapter.FeeParams memory _feeParams
        ) = abi.decode(data, (
                uint32[],
                bytes32,
                address,
                bytes32,
                uint256,
                uint24,
                uint48,
                bytes,
                IFeeAdapter.FeeParams
            ));
        
        console2.log("---------------_destinations", uint256(_destinations[0]));
        console2.log("---------------_destinations length", _destinations.length);
        console2.log("---------------_receiver");
        console2.logBytes32(_receiver);
        console2.log("---------------_inputAsset", _inputAsset);
        console2.log("---------------_outputAsset");
        console2.logBytes32(_outputAsset);
        console2.log("---------------_amount", _amount);
        console2.log("---------------_maxFee", uint256(_maxFee));
        console2.log("---------------_ttl", uint256(_ttl));
        console2.log("---------------_feeParams.fee", _feeParams.fee);
        console2.log("---------------_feeParams.deadline", _feeParams.deadline);
    }

    function test_WhenSetWhitelistedBridgeStatusIsCalledWithTrue() external givenSenderDoesNotHaveGUARDIAN_BRIDGERole {
        vm.expectRevert(IRebalancer.Rebalancer_NotAuthorized.selector);
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        // it should not set a bridge and revert with Rebalancer_NotAuthorized
    }

    function test_WhenSetWhitelistedBridgeStatusIsCalledWithFalse()
        external
        givenSenderDoesNotHaveGUARDIAN_BRIDGERole
    {
        vm.expectRevert(IRebalancer.Rebalancer_NotAuthorized.selector);
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        // it should not set a bridge and revert with Rebalancer_NotAuthorized
    }

    modifier givenSenderHasRoleGUARDIAN_BRIDGE() {
        roles.allowFor(address(this), roles.GUARDIAN_BRIDGE(), true);
        _;
    }

    function test_WhenSetWhitelistedBridgeStatusIsCalledToWhitelist() external givenSenderHasRoleGUARDIAN_BRIDGE {
        // it should whitelist a bridge
        vm.expectEmit(true, true, true, true);
        emit IRebalancer.BridgeWhitelistedStatusUpdated(address(bridgeMock), true);
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
    }

    function test_WhenIsBridgeWhitelistedIsCalled() external givenSenderHasRoleGUARDIAN_BRIDGE {
        // it should return true
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        bool isWhitelisted = rebalancer.isBridgeWhitelisted(address(bridgeMock));
        assertTrue(isWhitelisted);
    }

    function test_WhenSetWhitelistedBridgeStatusIsCalledToRemoveFromWhitelist()
        external
        givenSenderHasRoleGUARDIAN_BRIDGE
    {
        // it should remove bridge from whitelist mapping
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        bool isWhitelisted = rebalancer.isBridgeWhitelisted(address(bridgeMock));
        assertTrue(isWhitelisted);
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), false);
        isWhitelisted = rebalancer.isBridgeWhitelisted(address(bridgeMock));
        assertFalse(isWhitelisted);
    }

    modifier givenSendMsgIsCalledWithWrongParameters() {
        _;
    }

    function test_WhenSenderDoesNotHaveREBALANCER_EOARole() external givenSendMsgIsCalledWithWrongParameters {
        // it should revert with Rebalancer_NotAuthorized
        IRebalancer.Msg memory _msg =
            IRebalancer.Msg({dstChainId: 0, token: address(weth), message: "", bridgeData: ""});
        vm.expectRevert(IRebalancer.Rebalancer_NotAuthorized.selector);
        rebalancer.sendMsg(address(bridgeMock), address(mWethHost), 1 ether, _msg);
    }

    function test_WhenBridgeIsNotWhitelisted() external givenSendMsgIsCalledWithWrongParameters {
        roles.allowFor(address(this), roles.REBALANCER_EOA(), true);
        IRebalancer.Msg memory _msg =
            IRebalancer.Msg({dstChainId: 0, token: address(weth), message: "", bridgeData: ""});
        vm.expectRevert(IRebalancer.Rebalancer_BridgeNotWhitelisted.selector);
        rebalancer.sendMsg(address(bridgeMock), address(mWethHost), 1 ether, _msg);
        // it should revert with Rebalancer_BridgeNotWhitelisted
    }

    function test_WhenUnderlyingIsNotTheSameToken()
        external
        givenSendMsgIsCalledWithWrongParameters
        givenSenderHasRoleGUARDIAN_BRIDGE
    {
        // it should revert with Rebalancer_RequestNotValid
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        rebalancer.setWhitelistedDestination(0, true);
        roles.allowFor(address(this), roles.REBALANCER_EOA(), true);
        IRebalancer.Msg memory _msg =
            IRebalancer.Msg({dstChainId: 0, token: address(usdc), message: "", bridgeData: ""});
        vm.expectRevert(IRebalancer.Rebalancer_RequestNotValid.selector);
        rebalancer.sendMsg(address(bridgeMock), address(mWethHost), 1 ether, _msg);
    }

    modifier givenSendMsgIsCalledWithRightParameters() {
        roles.allowFor(address(this), roles.REBALANCER_EOA(), true);
        _;
    }

    function test_RevertWhen_MarketDoesNotHaveEnoughTokens()
        external
        givenSendMsgIsCalledWithRightParameters
        givenSenderHasRoleGUARDIAN_BRIDGE
    {
        // it should revert
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        IRebalancer.Msg memory _msg =
            IRebalancer.Msg({dstChainId: 0, token: address(weth), message: "", bridgeData: ""});
        vm.expectRevert();
        rebalancer.sendMsg(address(bridgeMock), address(mWethHost), 1 ether, _msg);
    }

    function test_WhenMarketHasEnoughTokensButTransferSizeIsNotMet(uint256 amount)
        external
        givenSendMsgIsCalledWithRightParameters
        givenSenderHasRoleGUARDIAN_BRIDGE
        inRange(amount, SMALL, LARGE)
    {
        rebalancer.setWhitelistedBridgeStatus(address(bridgeMock), true);
        rebalancer.setMaxTransferSize(0, address(weth), amount - 1);
        IRebalancer.Msg memory _msg =
            IRebalancer.Msg({dstChainId: 0, token: address(weth), message: abi.encode(amount), bridgeData: ""});
        _getTokens(weth, address(mWethHost), amount);
        vm.expectRevert();
        rebalancer.sendMsg(address(bridgeMock), address(mWethHost), amount, _msg);
    }
}
