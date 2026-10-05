// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Test } from "forge-std/Test.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract TokenActor {
    NewTibetCoin internal immutable TOKEN;

    constructor(NewTibetCoin token_) {
        TOKEN = token_;
    }

    function transferToken(address to, uint256 amount) external {
        require(TOKEN.transfer(to, amount), "transfer failed");
    }

    function burnToken(uint256 amount) external {
        ERC20Burnable(address(TOKEN)).burn(amount);
    }
}

contract NewTibetCoinHandler {
    NewTibetCoin public token;
    TokenActor[3] internal actors;

    bool public lockedBalanceReductionObserved;
    bool public releaseObserved;

    function initialize(NewTibetCoin token_) external {
        require(address(token) == address(0), "already initialized");
        token = token_;
        actors[0] = new TokenActor(token_);
        actors[1] = new TokenActor(token_);
        actors[2] = new TokenActor(token_);
    }

    function distribute(uint256 actorSeed, uint256 amountSeed) external {
        uint256 balance = token.balanceOf(address(this));
        uint256 amount = _amount(amountSeed, balance);
        require(token.transfer(actorAddress(actorSeed), amount), "distribution failed");
    }

    function burnFromFoundation(uint256 amountSeed) external {
        uint256 balance = token.balanceOf(address(this));
        ERC20Burnable(address(token)).burn(_amount(amountSeed, balance));
    }

    function attemptLockedTransfer(uint256 actorSeed, uint256 recipientSeed, uint256 amountSeed)
        external
    {
        if (token.transfersEnabled()) return;

        TokenActor actor = actors[actorSeed % actors.length];
        uint256 balanceBefore = token.balanceOf(address(actor));

        try actor.transferToken(actorAddress(recipientSeed), _amount(amountSeed, balanceBefore)) {
            if (token.balanceOf(address(actor)) < balanceBefore) {
                lockedBalanceReductionObserved = true;
            }
        } catch { }
    }

    function attemptLockedBurn(uint256 actorSeed, uint256 amountSeed) external {
        if (token.transfersEnabled()) return;

        TokenActor actor = actors[actorSeed % actors.length];
        uint256 balanceBefore = token.balanceOf(address(actor));

        try actor.burnToken(_amount(amountSeed, balanceBefore)) {
            if (token.balanceOf(address(actor)) < balanceBefore) {
                lockedBalanceReductionObserved = true;
            }
        } catch { }
    }

    function enableTransfers() external {
        if (token.transfersEnabled()) return;
        token.enableTransfers();
        releaseObserved = true;
    }

    function transferAfterRelease(uint256 actorSeed, uint256 recipientSeed, uint256 amountSeed)
        external
    {
        if (!token.transfersEnabled()) return;

        uint256 actorIndex = actorSeed % actors.length;
        TokenActor actor = actors[actorIndex];
        uint256 recipientIndex =
            (actorIndex + 1 + (recipientSeed % (actors.length - 1))) % actors.length;
        uint256 balance = token.balanceOf(address(actor));
        actor.transferToken(address(actors[recipientIndex]), _amount(amountSeed, balance));
    }

    function burnAfterRelease(uint256 actorSeed, uint256 amountSeed) external {
        if (!token.transfersEnabled()) return;

        TokenActor actor = actors[actorSeed % actors.length];
        uint256 balance = token.balanceOf(address(actor));
        actor.burnToken(_amount(amountSeed, balance));
    }

    function actorAddress(uint256 seed) public view returns (address) {
        return address(actors[seed % actors.length]);
    }

    function _amount(uint256 seed, uint256 maximum) internal pure returns (uint256) {
        return maximum == type(uint256).max ? seed : seed % (maximum + 1);
    }
}

contract NewTibetCoinInvariantTest is StdInvariant, Test {
    NewTibetCoin internal token;
    NewTibetCoinHandler internal handler;

    function setUp() public {
        handler = new NewTibetCoinHandler();
        token = new NewTibetCoin(address(handler));
        handler.initialize(token);

        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = handler.distribute.selector;
        selectors[1] = handler.burnFromFoundation.selector;
        selectors[2] = handler.attemptLockedTransfer.selector;
        selectors[3] = handler.attemptLockedBurn.selector;
        selectors[4] = handler.enableTransfers.selector;
        selectors[5] = handler.transferAfterRelease.selector;
        selectors[6] = handler.burnAfterRelease.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    function invariant_TotalSupplyNeverExceedsInitialSupply() public view {
        assertLe(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function invariant_LockedHoldersNeverReduceTheirBalances() public view {
        assertFalse(handler.lockedBalanceReductionObserved());
    }

    function invariant_ReleaseNeverReverses() public view {
        if (handler.releaseObserved()) assertTrue(token.transfersEnabled());
    }

    function invariant_AllSupplyIsAccountedFor() public view {
        uint256 accounted = token.balanceOf(address(handler));
        accounted += token.balanceOf(handler.actorAddress(0));
        accounted += token.balanceOf(handler.actorAddress(1));
        accounted += token.balanceOf(handler.actorAddress(2));
        assertEq(accounted, token.totalSupply());
    }
}
