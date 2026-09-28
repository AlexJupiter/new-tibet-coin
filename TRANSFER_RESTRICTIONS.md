# Transfer-restriction model

The token has two states controlled by one irreversible boolean.

## Distribution phase

`transfersEnabled == false`

- The Foundation Safe holds the initial supply.
- The Safe can distribute tokens to recipients.
- Recipients own their balances and may delegate voting power.
- No other address can transfer, `transferFrom`, burn or `burnFrom` tokens.

## Released phase

The Foundation Safe calls `enableTransfers()` once.

- `transfersEnabled` becomes `true` permanently.
- Every holder can use standard ERC-20 transfers and burns immediately.
- There is no pause, reversal, administrator migration, distributor registry or individual lock.

## Foundation operating sequence

1. Deploy the token with the Foundation Safe address.
2. Distribute tokens from the Safe while general transfers remain disabled.
3. Reconcile balances and obtain the required Safe approval for release.
4. Execute `enableTransfers()` through the Safe.

Different vesting schedules require separate vesting contracts. They are intentionally outside
the token contract.
