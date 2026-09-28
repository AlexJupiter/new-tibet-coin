# Audit scope

## Version under review

This scope applies to the `transfer-restrictions-v2` branch. It is an undeployed audit candidate.
The immutable Sepolia V1 contract is a historical test baseline and is not the contract under
review.

## In scope

- `src/NewTibetCoin.sol`
- Its composition with OpenZeppelin Contracts v5.6.0:
  - `ERC20`
  - `ERC20Burnable`
  - `ERC20Permit`
  - `ERC20Votes`
  - `Nonces`
- Constructor and deployment assumptions
- Fixed supply, burning, Permit, delegation and checkpoint behavior
- Global pre-activation transfer restriction
- Authorized distributor configuration
- One-time recipient lock configuration and activation-relative unlock calculation
- Enforcement through `_update`, including transfer, `transferFrom`, burn and `burnFrom`
- Two-step token-administrator migration
- Inheritance resolution in `_update` and `nonces`

## Primary security properties

1. Exactly 13,000,000,000 tokens are minted once during construction.
2. The complete initial supply is minted to the constructor-supplied Foundation Safe, which must
   be a deployed contract.
3. No external mint function, proxy or post-deployment supply expansion exists.
4. Before global activation, only authorized source addresses can transfer or burn tokens.
5. Authorized distributors can be added or removed only by the token administrator and only
   before global activation.
6. A recipient lock can be configured only once, before the recipient has a balance, and cannot
   be shortened, extended or removed.
7. Global activation is irreversible, stores its timestamp and permanently closes distributor
   and lock configuration.
8. A locked address cannot transfer or burn until `transfersEnabledAt + lockDuration[address]`.
9. Allowances, EIP-2612 Permit, `transferFrom`, `burnFrom`, contracts, wrappers and exchange
   deposit flows cannot bypass the source-address restriction enforced by `_update`.
10. Token administration can migrate only after the current administrator nominates another
    deployed contract and that contract accepts.
11. The administrator cannot mint, confiscate, rebase, tax, blacklist individual holders, reverse
    activation, or modify an existing recipient lock.
12. ERC20Votes delegation and checkpoints remain consistent across mint, transfer and burn
    operations. Delegation itself is permitted while tokens are transfer-locked.

## Privileged operations and trust assumptions

- Before activation, the token administrator can authorize an address as a distributor. Such an
  address can send any TIBET that it owns while general transfers remain disabled.
- The token administrator chooses recipient lock durations and the moment of global activation.
- The Foundation Safe's threshold, signer selection, transaction policy and operational security
  are trusted and must be reviewed separately.
- Moving token administration does not automatically move token balances or change the
  authorized-distributor list. Any required distributor changes must occur before activation.

## Out of scope

- Foundation Safe implementation, modules, guards, signer devices and signer security
- Allocation calculations and off-chain recipient data
- Separate vesting, sale, staking, rewards, UBI or payment contracts
- Exchanges, bridges and wrapped versions
- Front ends, off-chain services and legal/compliance analysis
- The deployment script except as it relates to constructor arguments

## Historical Sepolia V1 baseline

- Network: Ethereum Sepolia (`11155111`)
- Contract: `0xD3D65E039fAC0b2924594061BE79E8089A0367d3`
- Deployment transaction: `0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793`

V1 does not contain V2 transfer restrictions. V2 must be deployed at a new address after its
requirements are finalized and the reviewed commit is selected.
