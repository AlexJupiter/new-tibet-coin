# Audit scope

## Version under review

This scope covers the minimal global-lock implementation with symbol `TIBETLOCKED2` on the
`transfer-restrictions-v2` branch. Earlier Sepolia deployments are historical test contracts.

## In scope

- `src/NewTibetCoin.sol`
- OpenZeppelin Contracts v5.6.0 composition: `ERC20`, `ERC20Burnable`, `ERC20Permit`,
  `ERC20Votes` and `Nonces`
- Constructor validation and fixed-supply mint
- Safe-only pre-release distribution
- Irreversible global transfer release
- Enforcement through `_update`, including transfer, `transferFrom`, burn and `burnFrom`
- Inheritance resolution in `_update` and `nonces`

## Primary security properties

1. Exactly 13,000,000,000 tokens are minted once to the constructor-supplied Foundation Safe.
2. The Foundation Safe must be a deployed contract.
3. No external mint function, proxy or post-deployment supply expansion exists.
4. Before release, only the Foundation Safe can be the source of a balance reduction.
5. Allowances, Permit, `transferFrom`, `burnFrom`, wrappers and exchange deposits cannot bypass
   the restriction.
6. Only the Foundation Safe can call `enableTransfers()`.
7. Release is global, irreversible and cannot be repeated.
8. After release, standard ERC-20 transfer and burn behavior applies to every holder.
9. The Safe cannot mint, confiscate, rebase, tax, blacklist, pause or reverse release.
10. ERC20Votes delegation remains available while transfers are disabled.

## Trust assumptions

- The Foundation Safe's threshold, signers, modules and operational security are trusted and
  reviewed separately.
- The Foundation accepts that its address cannot be replaced in this immutable token.
- The Foundation chooses recipients, amounts and the release time through its Safe process.

## Out of scope

- Individual vesting schedules or recipient-specific locks
- Additional distributor addresses or administrator migration
- Foundation Safe implementation and signer security
- Allocation calculations and off-chain recipient data
- Sale, staking, rewards, UBI, payment, bridge and wrapped-token contracts
- Front ends and legal or compliance analysis
