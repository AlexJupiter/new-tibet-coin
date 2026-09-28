// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { Test } from "forge-std/Test.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract MockFoundationSafe { }

contract NewTibetCoinTest is Test {
    uint64 internal constant ONE_YEAR = 365 days;

    NewTibetCoin internal token;
    MockFoundationSafe internal foundationSafe;

    address internal holder = makeAddr("holder");
    address internal recipient = makeAddr("recipient");
    address internal distributor = makeAddr("distributor");

    function setUp() public {
        foundationSafe = new MockFoundationSafe();
        token = new NewTibetCoin(address(foundationSafe));
    }

    function test_MetadataAndInitialState() public view {
        assertEq(token.name(), "New Tibet Coin");
        assertEq(token.symbol(), "TIBETLOCKED");
        assertEq(token.decimals(), 18);
        assertEq(token.INITIAL_SUPPLY(), 13_000_000_000 ether);
        assertEq(token.totalSupply(), 13_000_000_000 ether);
        assertEq(token.balanceOf(address(foundationSafe)), 13_000_000_000 ether);
        assertEq(token.tokenAdministrator(), address(foundationSafe));
        assertTrue(token.authorizedDistributor(address(foundationSafe)));
        assertFalse(token.transfersEnabled());
        assertEq(token.transfersEnabledAt(), 0);
    }

    function test_ConstructorRejectsZeroAddress() public {
        vm.expectRevert(NewTibetCoin.InvalidFoundationSafe.selector);
        new NewTibetCoin(address(0));
    }

    function test_ConstructorRejectsEOA() public {
        vm.expectRevert(NewTibetCoin.InvalidFoundationSafe.selector);
        new NewTibetCoin(makeAddr("eoa"));
    }

    function test_FoundationSafeCanDistributeBeforeActivation() public {
        _safeTransfer(holder, 100 ether);

        assertEq(token.balanceOf(holder), 100 ether);
        assertEq(token.balanceOf(address(foundationSafe)), token.INITIAL_SUPPLY() - 100 ether);
    }

    function test_AuthorizedDistributorCanDistributeBeforeActivation() public {
        _setDistributor(distributor, true);
        _safeTransfer(distributor, 100 ether);

        vm.prank(distributor);
        assertTrue(token.transfer(recipient, 40 ether));

        assertEq(token.balanceOf(recipient), 40 ether);
    }

    function test_OrdinaryHolderCannotTransferBeforeActivation() public {
        _safeTransfer(holder, 100 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        token.transfer(recipient, 1 ether);
    }

    function test_OrdinaryHolderCannotBurnBeforeActivation() public {
        _safeTransfer(holder, 100 ether);

        vm.expectRevert(NewTibetCoin.TransfersDisabled.selector);
        vm.prank(holder);
        token.burn(1 ether);
    }

    function test_OnlyAdministratorCanConfigureTransferControls() public {
        address attacker = makeAddr("attacker");
        MockFoundationSafe replacement = new MockFoundationSafe();

        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, attacker));
        token.configureLock(holder, ONE_YEAR);
        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, attacker));
        token.setAuthorizedDistributor(distributor, true);
        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, attacker));
        token.enableTransfers();
        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, attacker));
        token.proposeTokenAdministrator(address(replacement));
        vm.stopPrank();
    }

    function test_LockMustBeConfiguredOnceBeforeFunding() public {
        _configureLock(holder, ONE_YEAR);

        assertEq(token.lockDuration(holder), ONE_YEAR);
        assertEq(token.lockedUntil(holder), type(uint256).max);

        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.LockAlreadyConfigured.selector, holder));
        vm.prank(address(foundationSafe));
        token.configureLock(holder, uint64(2 * ONE_YEAR));

        _safeTransfer(recipient, 1 ether);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.RecipientAlreadyFunded.selector, recipient)
        );
        vm.prank(address(foundationSafe));
        token.configureLock(recipient, ONE_YEAR);
    }

    function test_LockRejectsInvalidRecipientAndDuration() public {
        vm.startPrank(address(foundationSafe));
        vm.expectRevert(NewTibetCoin.InvalidRecipient.selector);
        token.configureLock(address(0), ONE_YEAR);
        vm.expectRevert(NewTibetCoin.InvalidLockDuration.selector);
        token.configureLock(holder, 0);
        vm.stopPrank();
    }

    function test_DistributorAndLockCannotBeCombined() public {
        _setDistributor(distributor, true);

        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.LockDistributorConflict.selector, distributor)
        );
        vm.prank(address(foundationSafe));
        token.configureLock(distributor, ONE_YEAR);

        _configureLock(holder, ONE_YEAR);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.LockDistributorConflict.selector, holder)
        );
        vm.prank(address(foundationSafe));
        token.setAuthorizedDistributor(holder, true);
    }

    function test_DistributorRejectsZeroAddress() public {
        vm.expectRevert(NewTibetCoin.InvalidDistributor.selector);
        vm.prank(address(foundationSafe));
        token.setAuthorizedDistributor(address(0), true);
    }

    function test_ActivationIsPermanentAndClosesConfiguration() public {
        _enableTransfers();

        assertTrue(token.transfersEnabled());
        assertEq(token.transfersEnabledAt(), block.timestamp);

        vm.expectRevert(NewTibetCoin.TransfersAlreadyEnabled.selector);
        vm.prank(address(foundationSafe));
        token.enableTransfers();

        vm.expectRevert(NewTibetCoin.DistributorConfigurationClosed.selector);
        vm.prank(address(foundationSafe));
        token.setAuthorizedDistributor(distributor, true);

        vm.expectRevert(NewTibetCoin.LockConfigurationClosed.selector);
        vm.prank(address(foundationSafe));
        token.configureLock(holder, ONE_YEAR);
    }

    function test_UnlockedHolderCanTransferAfterActivation() public {
        _safeTransfer(holder, 100 ether);
        _enableTransfers();

        vm.prank(holder);
        assertTrue(token.transfer(recipient, 25 ether));

        assertEq(token.balanceOf(recipient), 25 ether);
    }

    function test_LockDurationStartsAtActivationAndEndsAtExactBoundary() public {
        _configureLock(holder, ONE_YEAR);
        _safeTransfer(holder, 100 ether);

        vm.warp(1_800_000_000);
        _enableTransfers();
        uint256 unlockTime = block.timestamp + ONE_YEAR;
        assertEq(token.lockedUntil(holder), unlockTime);

        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, holder, unlockTime)
        );
        vm.prank(holder);
        token.transfer(recipient, 1 ether);

        vm.warp(unlockTime - 1);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, holder, unlockTime)
        );
        vm.prank(holder);
        token.transfer(recipient, 1 ether);

        vm.warp(unlockTime);
        vm.prank(holder);
        assertTrue(token.transfer(recipient, 1 ether));
    }

    function test_TransferFromCannotBypassLockAndAllowanceIsPreserved() public {
        address spender = makeAddr("spender");
        _configureLock(holder, ONE_YEAR);
        _safeTransfer(holder, 100 ether);
        _enableTransfers();

        vm.prank(holder);
        token.approve(spender, 25 ether);

        uint256 unlockTime = token.lockedUntil(holder);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, holder, unlockTime)
        );
        vm.prank(spender);
        token.transferFrom(holder, recipient, 25 ether);

        assertEq(token.allowance(holder, spender), 25 ether);
        assertEq(token.balanceOf(holder), 100 ether);
    }

    function test_PermitCannotBypassLock() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = makeAddr("spender");
        _configureLock(owner, ONE_YEAR);
        _safeTransfer(owner, 100 ether);
        _enableTransfers();

        _permit(ownerPrivateKey, owner, spender, 25 ether, block.timestamp + 1 days);
        assertEq(token.allowance(owner, spender), 25 ether);

        uint256 unlockTime = token.lockedUntil(owner);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, owner, unlockTime)
        );
        vm.prank(spender);
        token.transferFrom(owner, recipient, 25 ether);
    }

    function test_BurnAndBurnFromCannotBypassLockButWorkAfterUnlock() public {
        address spender = makeAddr("spender");
        _configureLock(holder, ONE_YEAR);
        _safeTransfer(holder, 100 ether);
        _enableTransfers();

        vm.prank(holder);
        token.approve(spender, 20 ether);

        uint256 unlockTime = token.lockedUntil(holder);
        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, holder, unlockTime)
        );
        vm.prank(holder);
        token.burn(10 ether);

        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.TokensLocked.selector, holder, unlockTime)
        );
        vm.prank(spender);
        token.burnFrom(holder, 20 ether);
        assertEq(token.allowance(holder, spender), 20 ether);

        vm.warp(unlockTime);
        vm.prank(holder);
        token.burn(10 ether);
        vm.prank(spender);
        token.burnFrom(holder, 20 ether);

        assertEq(token.balanceOf(holder), 70 ether);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() - 30 ether);
    }

    function test_DelegationWorksWhileTokensAreLocked() public {
        _configureLock(holder, ONE_YEAR);
        _safeTransfer(holder, 100 ether);

        vm.prank(holder);
        token.delegate(holder);

        assertEq(token.getVotes(holder), 100 ether);
    }

    function test_AdministratorMigrationRequiresDeployedContractAndAcceptance() public {
        MockFoundationSafe nextSafe = new MockFoundationSafe();
        address eoa = makeAddr("eoa");

        vm.startPrank(address(foundationSafe));
        vm.expectRevert(NewTibetCoin.InvalidTokenAdministrator.selector);
        token.proposeTokenAdministrator(address(0));
        vm.expectRevert(NewTibetCoin.InvalidTokenAdministrator.selector);
        token.proposeTokenAdministrator(eoa);
        token.proposeTokenAdministrator(address(nextSafe));
        vm.stopPrank();

        assertEq(token.pendingTokenAdministrator(), address(nextSafe));

        vm.expectRevert(abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, eoa));
        vm.prank(eoa);
        token.acceptTokenAdministrator();

        vm.prank(address(nextSafe));
        token.acceptTokenAdministrator();

        assertEq(token.tokenAdministrator(), address(nextSafe));
        assertEq(token.pendingTokenAdministrator(), address(0));

        vm.expectRevert(
            abi.encodeWithSelector(NewTibetCoin.Unauthorized.selector, address(foundationSafe))
        );
        vm.prank(address(foundationSafe));
        token.configureLock(holder, ONE_YEAR);

        vm.prank(address(nextSafe));
        token.configureLock(holder, ONE_YEAR);
        assertEq(token.lockDuration(holder), ONE_YEAR);
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

    function _configureLock(address account, uint64 duration) internal {
        vm.prank(address(foundationSafe));
        token.configureLock(account, duration);
    }

    function _setDistributor(address account, bool authorised) internal {
        vm.prank(address(foundationSafe));
        token.setAuthorizedDistributor(account, authorised);
    }

    function _enableTransfers() internal {
        vm.prank(address(foundationSafe));
        token.enableTransfers();
    }

    function _permit(
        uint256 ownerPrivateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal {
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
    }
}
