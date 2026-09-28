// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

/// @title New Tibet Coin
/// @notice A fixed-supply ERC-20 with burning, permit approvals, vote checkpoints, and
///         Foundation-controlled transfer activation and recipient lock-ups.
/// @dev The code is immutable. Administrative authority is limited to transfer controls and can
///      migrate only through a two-step handover to another deployed contract, such as a Safe.
contract NewTibetCoin is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    /// @notice The exact number of tokens minted during construction, including 18 decimals.
    uint256 public constant INITIAL_SUPPLY = 13_000_000_000 ether;

    /// @notice The Safe currently permitted to administer transfer restrictions.
    address public tokenAdministrator;

    /// @notice A proposed replacement administrator that must accept its role.
    address public pendingTokenAdministrator;

    /// @notice The timestamp at which unrestricted transfers were irreversibly activated.
    /// @dev Zero means unrestricted transfers have not yet been activated.
    uint64 public transfersEnabledAt;

    /// @notice Sources permitted to distribute tokens before unrestricted transfers are enabled.
    mapping(address distributor => bool authorised) public authorizedDistributor;

    /// @notice Per-address lock duration measured from `transfersEnabledAt`.
    /// @dev Zero means the address has no post-activation lock. A non-zero value can be set once.
    mapping(address account => uint64 duration) public lockDuration;

    error InvalidFoundationSafe();
    error Unauthorized(address caller);
    error InvalidTokenAdministrator();
    error InvalidDistributor();
    error DistributorConfigurationClosed();
    error LockConfigurationClosed();
    error InvalidRecipient();
    error InvalidLockDuration();
    error LockAlreadyConfigured(address recipient);
    error RecipientAlreadyFunded(address recipient);
    error LockDistributorConflict(address account);
    error TransfersAlreadyEnabled();
    error TransfersDisabled();
    error TokensLocked(address account, uint256 unlockTime);

    event TokenAdministratorTransferStarted(
        address indexed currentAdministrator, address indexed pendingAdministrator
    );
    event TokenAdministratorTransferred(
        address indexed previousAdministrator, address indexed newAdministrator
    );
    event AuthorizedDistributorSet(address indexed distributor, bool authorised);
    event LockConfigured(address indexed recipient, uint64 duration);
    event TransfersEnabled(uint64 indexed enabledAt);

    modifier onlyTokenAdministrator() {
        _checkTokenAdministrator();
        _;
    }

    function _checkTokenAdministrator() internal view {
        if (_msgSender() != tokenAdministrator) revert Unauthorized(_msgSender());
    }

    /// @param foundationSafe A deployed Foundation Safe that receives the complete initial supply
    ///        and becomes the initial token administrator and authorised distributor.
    constructor(address foundationSafe)
        ERC20("New Tibet Coin", "TIBET")
        ERC20Permit("New Tibet Coin")
    {
        if (foundationSafe == address(0) || foundationSafe.code.length == 0) {
            revert InvalidFoundationSafe();
        }

        tokenAdministrator = foundationSafe;
        authorizedDistributor[foundationSafe] = true;

        emit TokenAdministratorTransferred(address(0), foundationSafe);
        emit AuthorizedDistributorSet(foundationSafe, true);

        _mint(foundationSafe, INITIAL_SUPPLY);
    }

    /// @notice Configures an irreversible lock duration before the recipient is funded.
    /// @dev Each separately locked tranche must use a fresh address. Once set, the duration cannot
    ///      be changed, shortened, extended, or removed.
    function configureLock(address recipient, uint64 duration) external onlyTokenAdministrator {
        if (transfersEnabledAt != 0) revert LockConfigurationClosed();
        if (recipient == address(0)) revert InvalidRecipient();
        if (duration == 0) revert InvalidLockDuration();
        if (lockDuration[recipient] != 0) revert LockAlreadyConfigured(recipient);
        if (balanceOf(recipient) != 0) revert RecipientAlreadyFunded(recipient);
        if (authorizedDistributor[recipient]) revert LockDistributorConflict(recipient);

        lockDuration[recipient] = duration;
        emit LockConfigured(recipient, duration);
    }

    /// @notice Adds or removes a pre-activation distribution source.
    /// @dev Distributor configuration closes permanently when unrestricted transfers are enabled.
    function setAuthorizedDistributor(address distributor, bool authorised)
        external
        onlyTokenAdministrator
    {
        if (transfersEnabledAt != 0) revert DistributorConfigurationClosed();
        if (distributor == address(0)) revert InvalidDistributor();
        if (authorised && lockDuration[distributor] != 0) {
            revert LockDistributorConflict(distributor);
        }

        authorizedDistributor[distributor] = authorised;
        emit AuthorizedDistributorSet(distributor, authorised);
    }

    /// @notice Irreversibly enables general transfers and starts all configured lock durations.
    function enableTransfers() external onlyTokenAdministrator {
        if (transfersEnabledAt != 0) revert TransfersAlreadyEnabled();

        transfersEnabledAt = uint64(block.timestamp);
        emit TransfersEnabled(transfersEnabledAt);
    }

    /// @notice Starts a two-step migration of token administration to another deployed contract.
    function proposeTokenAdministrator(address newAdministrator) external onlyTokenAdministrator {
        if (
            newAdministrator == address(0) || newAdministrator == tokenAdministrator
                || newAdministrator.code.length == 0
        ) {
            revert InvalidTokenAdministrator();
        }

        pendingTokenAdministrator = newAdministrator;
        emit TokenAdministratorTransferStarted(tokenAdministrator, newAdministrator);
    }

    /// @notice Accepts token administration from the currently proposed replacement contract.
    function acceptTokenAdministrator() external {
        address caller = _msgSender();
        if (caller != pendingTokenAdministrator) revert Unauthorized(caller);

        address previousAdministrator = tokenAdministrator;
        tokenAdministrator = caller;
        pendingTokenAdministrator = address(0);

        emit TokenAdministratorTransferred(previousAdministrator, caller);
    }

    /// @notice Returns true once unrestricted transfers have been irreversibly enabled.
    function transfersEnabled() public view returns (bool) {
        return transfersEnabledAt != 0;
    }

    /// @notice Returns the effective unlock time for an address.
    /// @return Zero if no lock is configured, the maximum uint256 value if activation has not yet
    ///         occurred, or the activation timestamp plus the configured duration.
    function lockedUntil(address account) public view returns (uint256) {
        uint64 duration = lockDuration[account];
        if (duration == 0) return 0;

        uint64 enabledAt = transfersEnabledAt;
        if (enabledAt == 0) return type(uint256).max;

        return uint256(enabledAt) + duration;
    }

    /// @dev Enforces both the global transfer gate and each sender's post-activation lock.
    ///      Because the check uses `from`, transferFrom, burning, wrapping, exchange deposits, and
    ///      other intermediary paths cannot bypass the restriction.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        if (from != address(0)) {
            uint64 enabledAt = transfersEnabledAt;

            if (enabledAt == 0) {
                if (!authorizedDistributor[from]) revert TransfersDisabled();
            } else {
                uint64 duration = lockDuration[from];
                if (duration != 0) {
                    uint256 unlockTime = uint256(enabledAt) + duration;
                    if (block.timestamp < unlockTime) revert TokensLocked(from, unlockTime);
                }
            }
        }

        super._update(from, to, value);
    }

    /// @dev Required by Solidity for the ERC20Permit and Nonces inheritance branches.
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
