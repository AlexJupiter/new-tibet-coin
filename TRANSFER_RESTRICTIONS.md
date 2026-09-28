# Transfer-restriction model

## State model

### 1. Distribution phase

`transfersEnabledAt == 0`

- The Foundation Safe holds the initial supply and is the first authorized distributor.
- The token administrator may add or remove other distributor addresses.
- Only an authorized distributor can be the source of a transfer or burn.
- Recipients own the tokens in their wallets, can inspect balances and can delegate voting power,
  but cannot transfer or burn them.
- A recipient lock is configured as a duration relative to the future activation timestamp. This
  avoids needing to know the ICO or exchange date when the token is deployed.

### 2. Global activation

The Foundation Safe calls `enableTransfers()` once.

- `transfersEnabledAt` is permanently set to the block timestamp.
- The action cannot be reversed or repeated.
- The authorized-distributor list and recipient locks can no longer be changed.
- Addresses without an individual lock can immediately send and burn.

### 3. Individual unlock

For an address with a configured duration, its effective unlock time is:

```text
transfersEnabledAt + lockDuration[address]
```

Until that timestamp, every outgoing balance change from the address reverts. At and after the
timestamp, standard ERC-20 transfer and burn behavior applies automatically; no Foundation
transaction is needed.

## Foundation operating sequence

1. Deploy and verify the production Foundation Safe.
2. Deploy `NewTibetCoin`, passing the Safe address to the constructor.
3. If needed, authorize narrowly scoped distributor contracts or wallets.
4. For each locked recipient, call `configureLock(recipient, duration)` before sending any tokens
   to that address.
5. Distribute tokens from the Safe or another authorized distributor.
6. Reconcile all allocations and locks off-chain against on-chain events and balances.
7. Before activation, remove any distributor that should not retain pre-activation authority.
8. At the approved ICO/exchange event, execute `enableTransfers()` through the Foundation Safe.

The exact production Safe address is not needed to compile or audit the contract because it is a
constructor argument. It is required before deployment, and the constructor rejects an EOA or an
address without deployed contract code.

## Important limitations

- Locks apply to addresses, not portions of a balance. Multiple tranches with different schedules
  require separate recipient addresses or a separately audited vesting contract.
- A lock cannot be edited after it is configured, even if the address was entered incorrectly.
- A lock cannot be added after an address has received any TIBET.
- Tokens received later by an already locked address inherit that address's existing unlock time.
- The token administrator can authorize powerful pre-activation distributors. Safe policy should
  require explicit review of each authorization and removal.
- Migrating the administrator uses a two-step nomination and acceptance flow. It does not move
  token balances or automatically change distributor status.
