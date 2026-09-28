# New Tibet Coin (`TIBETLOCKED`)

Audit-candidate source for a fixed-supply ERC-20 with Foundation-controlled transfer activation
and irreversible recipient lock-ups.

> This branch is version 2 and has not been deployed. The existing Sepolia contract is the
> immutable version 1 baseline and does not contain these transfer restrictions.

## Contract summary

| Property | Value |
| --- | --- |
| Name | New Tibet Coin |
| Symbol | `TIBETLOCKED` |
| Decimals | 18 |
| Initial supply | 13,000,000,000 TIBETLOCKED |
| Future minting | None |
| Upgradeability | None |
| Initial token administrator | Constructor-supplied Foundation Safe |
| Extensions | Burnable, EIP-2612 Permit, ERC20Votes |

The complete project-specific implementation is
[`src/NewTibetCoin.sol`](src/NewTibetCoin.sol). Standard ERC-20 behavior and extensions are
provided by pinned OpenZeppelin Contracts dependencies.

## Transfer restrictions

- The complete supply is minted to a deployed Foundation Safe.
- Before global activation, only Foundation-approved distributor addresses can send tokens.
- The token administrator can configure a recipient's lock duration once, before that address is
  funded. The duration cannot subsequently be changed or removed.
- Global activation is a one-way action. It records the activation timestamp and permanently
  closes distributor and lock configuration.
- A configured recipient remains unable to send or burn until its duration, measured from the
  activation timestamp, has elapsed.
- Enforcement occurs in the common ERC-20 `_update` path, so `transferFrom`, Permit allowances,
  burning, exchange deposits, wrappers and other intermediary paths cannot bypass it.
- Administrative authority can move only through a two-step handover to another deployed
  contract, such as a replacement Safe.

See [`TRANSFER_RESTRICTIONS.md`](TRANSFER_RESTRICTIONS.md) for the state model and operational
sequence.

## Existing Sepolia V1 baseline

- Contract: [`0xD3D65E039fAC0b2924594061BE79E8089A0367d3`](https://sepolia.etherscan.io/address/0xD3D65E039fAC0b2924594061BE79E8089A0367d3#code)
- Sourcify: [`exact_match`](https://sourcify.dev/server/v2/contract/11155111/0xD3D65E039fAC0b2924594061BE79E8089A0367d3?fields=match,creationMatch,runtimeMatch)
- Deployment transaction: [`0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793`](https://sepolia.etherscan.io/tx/0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793)

V1 is retained as a public test baseline only. Because it is immutable, V2 requires a new
deployment after review and audit.

## Reproducible compiler settings

- Solidity: `0.8.35+commit.47b9dedd`
- EVM version: `cancun`
- Optimizer: enabled
- Optimizer runs: `200`
- Via IR: disabled
- Metadata bytecode hash: IPFS
- OpenZeppelin Contracts: `v5.6.0`

## Build and test

Install [Foundry](https://book.getfoundry.sh/getting-started/installation), clone the V2 branch
with submodules, then run:

```sh
git clone --branch transfer-restrictions-v2 --recurse-submodules \
  https://github.com/AlexJupiter/new-tibet-coin.git
cd new-tibet-coin
forge fmt --check
forge build --sizes
forge test -vvv
```

## Audit quotation

See [`AUDIT_SCOPE.md`](AUDIT_SCOPE.md) for the proposed review scope, security properties and
explicitly excluded systems. This code has automated tests but has not yet received an external
security audit.

## Security warning

Never commit private keys, keystores, RPC credentials or API keys. Deployment secrets must be
provided through a secure local keystore or environment and are intentionally absent here.

## License

MIT
