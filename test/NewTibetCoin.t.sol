// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import { Test } from "forge-std/Test.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract MockFoundationSafe { }

contract NewTibetCoinTest is Test {
    bytes32 internal constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    uint256 internal constant PERMIT_OWNER_KEY = 0xA11CE;

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

    function test_FoundationSafeCanBurnBeforeRelease() public {
        vm.prank(address(foundationSafe));
        token.burn(100 ether);

        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() - 100 ether);
        assertEq(token.balanceOf(address(foundationSafe)), token.INITIAL_SUPPLY() - 100 ether);
        assertFalse(token.transfersEnabled());
    }

    function test_HolderCannotReduceBalanceBeforeRelease() public {
        _safeTransfer(holder, 100 ether);
        vm.prank(holder);
        token.approve(spender, 25 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(recipient, 1 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        token.burn(1 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(spender);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transferFrom(holder, recipient, 25 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(spender);
        token.burnFrom(holder, 25 ether);

        assertEq(token.allowance(holder, spender), 25 ether);
        assertEq(token.balanceOf(holder), 100 ether);
    }

    function test_LockedHolderCannotMakeZeroValueTransfer() public {
        _safeTransfer(holder, 100 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(recipient, 0);
    }

    function test_PermitSetsAllowanceButCannotBypassLock() public {
        address permitOwner = vm.addr(PERMIT_OWNER_KEY);
        uint256 value = 25 ether;
        uint256 deadline = block.timestamp + 1 days;
        _safeTransfer(permitOwner, 100 ether);

        uint256 nonce = token.nonces(permitOwner);
        bytes32 digest = _permitDigest(permitOwner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PERMIT_OWNER_KEY, digest);

        token.permit(permitOwner, spender, value, deadline, v, r, s);

        assertEq(token.nonces(permitOwner), nonce + 1);
        assertEq(token.allowance(permitOwner, spender), value);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(spender);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transferFrom(permitOwner, recipient, value);

        assertEq(token.allowance(permitOwner, spender), value);
        assertEq(token.balanceOf(permitOwner), 100 ether);

        _enableTransfers();
        vm.prank(spender);
        assertTrue(token.transferFrom(permitOwner, recipient, value));

        assertEq(token.allowance(permitOwner, spender), 0);
        assertEq(token.balanceOf(recipient), value);
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
        assertTrue(token.transfer(recipient, 20 ether));
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

    function test_VoteCheckpointsTrackTransfersAndBurnsAfterRelease() public {
        _safeTransfer(holder, 100 ether);
        vm.prank(holder);
        token.delegate(holder);

        vm.roll(block.number + 1);
        _enableTransfers();

        vm.prank(holder);
        assertTrue(token.transfer(recipient, 20 ether));
        vm.prank(recipient);
        token.delegate(recipient);
        vm.prank(holder);
        token.burn(10 ether);

        assertEq(token.getVotes(holder), 70 ether);
        assertEq(token.getVotes(recipient), 20 ether);

        uint256 checkpointBlock = block.number;
        vm.roll(checkpointBlock + 1);
        assertEq(token.getPastVotes(holder, checkpointBlock), 70 ether);
        assertEq(token.getPastVotes(recipient, checkpointBlock), 20 ether);
    }

    function test_NoExternalMintFunctionExists() public {
        (bool success,) = address(token)
            .call(abi.encodeWithSignature("mint(address,uint256)", address(this), 1 ether));
        assertFalse(success);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function testFuzz_FoundationSafeCanDistribute(address to, uint256 amountSeed) public {
        vm.assume(to != address(0) && to != address(foundationSafe));
        uint256 amount = bound(amountSeed, 1, token.INITIAL_SUPPLY());

        _safeTransfer(to, amount);

        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function testFuzz_LockedHolderCannotTransfer(
        address to,
        uint256 balanceSeed,
        uint256 amountSeed
    ) public {
        vm.assume(to != address(0) && to != holder && to != address(foundationSafe));
        uint256 balance = bound(balanceSeed, 1, token.INITIAL_SUPPLY());
        uint256 amount = bound(amountSeed, 0, balance);
        _safeTransfer(holder, balance);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(to, amount);

        assertEq(token.balanceOf(holder), balance);
        assertEq(token.balanceOf(to), 0);
    }

    function testFuzz_HolderCanTransferAfterRelease(
        address to,
        uint256 balanceSeed,
        uint256 amountSeed
    ) public {
        vm.assume(to != address(0) && to != holder && to != address(foundationSafe));
        uint256 balance = bound(balanceSeed, 1, token.INITIAL_SUPPLY());
        uint256 amount = bound(amountSeed, 0, balance);
        _safeTransfer(holder, balance);
        _enableTransfers();

        vm.prank(holder);
        assertTrue(token.transfer(to, amount));

        assertEq(token.balanceOf(holder), balance - amount);
        assertEq(token.balanceOf(to), amount);
    }

    function _safeTransfer(address to, uint256 amount) internal {
        vm.prank(address(foundationSafe));
        assertTrue(token.transfer(to, amount));
    }

    function _enableTransfers() internal {
        vm.prank(address(foundationSafe));
        token.enableTransfers();
    }

    function _permitDigest(
        address owner,
        address permitSpender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, permitSpender, value, nonce, deadline)
        );
        return keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
    }
}
