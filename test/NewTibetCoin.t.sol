// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { Test } from "forge-std/Test.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract NewTibetCoinTest is Test {
    NewTibetCoin internal token;
    address internal treasury;

    function setUp() public {
        treasury = makeAddr("foundationTreasury");
        token = new NewTibetCoin(treasury);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "New Tibet Coin");
        assertEq(token.symbol(), "TIBET");
        assertEq(token.decimals(), 18);
    }

    function test_InitialSupplyIsMintedOnlyToTreasury() public view {
        assertEq(token.INITIAL_SUPPLY(), 13_000_000_000 ether);
        assertEq(token.totalSupply(), 13_000_000_000 ether);
        assertEq(token.balanceOf(treasury), 13_000_000_000 ether);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function test_RevertWhenTreasuryIsZeroAddress() public {
        vm.expectRevert(NewTibetCoin.InvalidTreasury.selector);
        new NewTibetCoin(address(0));
    }

    function test_TransfersUseStandardERC20Behavior() public {
        address recipient = makeAddr("recipient");

        vm.prank(treasury);
        assertTrue(token.transfer(recipient, 25 ether));

        assertEq(token.balanceOf(recipient), 25 ether);
        assertEq(token.balanceOf(treasury), token.INITIAL_SUPPLY() - 25 ether);
    }

    function test_HolderCanBurnOwnTokens() public {
        address holder = makeAddr("holder");
        vm.prank(treasury);
        assertTrue(token.transfer(holder, 100 ether));

        vm.prank(holder);
        token.burn(40 ether);

        assertEq(token.balanceOf(holder), 60 ether);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() - 40 ether);
    }

    function test_ApprovedSpenderCanBurnFromAllowance() public {
        address holder = makeAddr("holder");
        address spender = makeAddr("spender");
        vm.prank(treasury);
        assertTrue(token.transfer(holder, 100 ether));

        vm.prank(holder);
        token.approve(spender, 30 ether);

        vm.prank(spender);
        token.burnFrom(holder, 30 ether);

        assertEq(token.balanceOf(holder), 70 ether);
        assertEq(token.allowance(holder, spender), 0);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() - 30 ether);
    }

    function test_PermitSetsAllowance() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = makeAddr("spender");
        uint256 value = 75 ether;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 permitTypehash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(permitTypehash, owner, spender, value, token.nonces(owner), deadline)
        );
        bytes32 digest =
            keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), 1);
    }

    function test_DelegationTracksVotingPower() public {
        address holder = makeAddr("holder");
        address recipient = makeAddr("recipient");
        vm.prank(treasury);
        assertTrue(token.transfer(holder, 100 ether));

        vm.prank(holder);
        token.delegate(holder);
        assertEq(token.getVotes(holder), 100 ether);

        vm.prank(holder);
        assertTrue(token.transfer(recipient, 40 ether));
        assertEq(token.getVotes(holder), 60 ether);
    }

    function test_NoExternalMintFunctionExists() public {
        (bool success,) = address(token)
            .call(abi.encodeWithSignature("mint(address,uint256)", address(this), 1 ether));
        assertFalse(success);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }
}
