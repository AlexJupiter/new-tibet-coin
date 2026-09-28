// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { Test } from "forge-std/Test.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract MockFoundationSafe { }

contract NewTibetCoinTest is Test {
    NewTibetCoin internal token;
    MockFoundationSafe internal foundationSafe;

    address internal holder = makeAddr("holder");
    address internal recipient = makeAddr("recipient");
    address internal spender = makeAddr("spender");

    function setUp() public {
        foundationSafe = new MockFoundationSafe();
        token = new NewTibetCoin(address(foundationSafe));
    }

    function test_MetadataAndInitialState() public view {
        assertEq(token.name(), "New Tibet Coin");
        assertEq(token.symbol(), "TIBETLOCKED2");
        assertEq(token.decimals(), 18);
        assertEq(token.INITIAL_SUPPLY(), 13_000_000_000 ether);
        assertEq(token.totalSupply(), 13_000_000_000 ether);
        assertEq(token.balanceOf(address(foundationSafe)), token.INITIAL_SUPPLY());
        assertEq(token.foundationSafe(), address(foundationSafe));
        assertFalse(token.transfersEnabled());
    }

    function test_ConstructorRejectsInvalidSafe() public {
        vm.expectRevert(NewTibetCoin.InvalidFoundationSafe.selector);
        new NewTibetCoin(address(0));

        vm.expectRevert(NewTibetCoin.InvalidFoundationSafe.selector);
        new NewTibetCoin(makeAddr("eoa"));
    }

    function test_FoundationSafeCanDistributeBeforeRelease() public {
        _safeTransfer(holder, 100 ether);

        assertEq(token.balanceOf(holder), 100 ether);
        assertEq(token.balanceOf(address(foundationSafe)), token.INITIAL_SUPPLY() - 100 ether);
    }

    function test_HolderCannotReduceBalanceBeforeRelease() public {
        _safeTransfer(holder, 100 ether);
        vm.prank(holder);
        token.approve(spender, 25 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        token.transfer(recipient, 1 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        token.burn(1 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(spender);
        token.transferFrom(holder, recipient, 25 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(spender);
        token.burnFrom(holder, 25 ether);

        assertEq(token.allowance(holder, spender), 25 ether);
        assertEq(token.balanceOf(holder), 100 ether);
    }

    function test_OnlyFoundationSafeCanEnableTransfers() public {
        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, holder));
        vm.prank(holder);
        token.enableTransfers();
    }

    function test_ReleaseIsPermanent() public {
        _enableTransfers();
        assertTrue(token.transfersEnabled());

        vm.expectRevert(NewTibetCoin.TransfersAlreadyEnabled.selector);
        vm.prank(address(foundationSafe));
        token.enableTransfers();
    }

    function test_HolderCanTransferAndBurnAfterRelease() public {
        _safeTransfer(holder, 100 ether);
        vm.prank(holder);
        token.approve(spender, 10 ether);
        _enableTransfers();

        vm.prank(holder);
        token.transfer(recipient, 20 ether);
        vm.prank(holder);
        token.burn(10 ether);
        vm.prank(spender);
        token.burnFrom(holder, 10 ether);

        assertEq(token.balanceOf(holder), 60 ether);
        assertEq(token.balanceOf(recipient), 20 ether);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() - 20 ether);
    }

    function test_DelegationWorksBeforeRelease() public {
        _safeTransfer(holder, 100 ether);

        vm.prank(holder);
        token.delegate(holder);

        assertEq(token.getVotes(holder), 100 ether);
    }

    function test_NoExternalMintFunctionExists() public {
        (bool success,) = address(token)
            .call(abi.encodeWithSignature("mint(address,uint256)", address(this), 1 ether));
        assertFalse(success);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function _safeTransfer(address to, uint256 amount) internal {
        vm.prank(address(foundationSafe));
        assertTrue(token.transfer(to, amount));
    }

    function _enableTransfers() internal {
        vm.prank(address(foundationSafe));
        token.enableTransfers();
    }
}
