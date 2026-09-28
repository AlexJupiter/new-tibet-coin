// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

/// @title New Tibet Coin
/// @notice Fixed-supply token with a one-way Foundation-controlled transfer release.
contract NewTibetCoin is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    uint256 public constant INITIAL_SUPPLY = 13_000_000_000 ether;

    address public immutable foundationSafe;
    bool public transfersEnabled;

    error InvalidFoundationSafe();
    error Unauthorized(address caller);
    error TransfersAlreadyEnabled();
    error TransfersDisabled();

    event TransfersEnabled();

    constructor(address foundationSafe_)
        ERC20("New Tibet Coin", "TIBETLOCKED2")
        ERC20Permit("New Tibet Coin")
    {
        if (foundationSafe_ == address(0) || foundationSafe_.code.length == 0) {
            revert InvalidFoundationSafe();
        }

        foundationSafe = foundationSafe_;
        _mint(foundationSafe_, INITIAL_SUPPLY);
    }

    /// @notice Permanently enables transfers for every holder.
    function enableTransfers() external {
        if (_msgSender() != foundationSafe) revert Unauthorized(_msgSender());
        if (transfersEnabled) revert TransfersAlreadyEnabled();

        transfersEnabled = true;
        emit TransfersEnabled();
    }

    /// @dev Before release, only the Foundation Safe can be the source of a balance reduction.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        if (!transfersEnabled && from != address(0) && from != foundationSafe) {
            revert TransfersDisabled();
        }
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
