// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

/// @title New Tibet Coin
/// @notice A fixed-supply, immutable ERC-20 with burning, permit approvals, and vote checkpoints.
/// @dev There is deliberately no owner, administrator, proxy, pause, blacklist, tax, or mint function.
contract NewTibetCoin is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    /// @notice The exact number of tokens minted during construction, including 18 decimals.
    uint256 public constant INITIAL_SUPPLY = 13_000_000_000 ether;

    error InvalidTreasury();

    /// @param treasury The Foundation Safe that receives the entire initial supply.
    constructor(address treasury) ERC20("New Tibet Coin", "TIBET") ERC20Permit("New Tibet Coin") {
        if (treasury == address(0)) revert InvalidTreasury();
        _mint(treasury, INITIAL_SUPPLY);
    }

    /// @dev Required by Solidity for the ERC20 and ERC20Votes inheritance branches.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// @dev Required by Solidity for the ERC20Permit and Nonces inheritance branches.
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
