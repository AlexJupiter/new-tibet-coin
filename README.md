# New Tibet Coin (`TIBET`)

Audit-ready source package for an immutable, fixed-supply ERC-20 token.

## Contract summary

| Property | Value |
| --- | --- |
| Name | New Tibet Coin |
| Symbol | `TIBET` |
| Decimals | 18 |
| Initial supply | 13,000,000,000 TIBET |
| Future minting | None |
| Upgradeability | None |
| Administrative owner | None |
| Extensions | Burnable, EIP-2612 Permit, ERC20Votes |

The complete project-specific implementation is
[`src/NewTibetCoin.sol`](src/NewTibetCoin.sol). Standard ERC-20 behavior and extensions are
provided by pinned OpenZeppelin Contracts dependencies.

## Sepolia deployment

- Contract: [`0xD3D65E039fAC0b2924594061BE79E8089A0367d3`](https://sepolia.etherscan.io/address/0xD3D65E039fAC0b2924594061BE79E8089A0367d3#code)
- Sourcify: [`exact_match`](https://sourcify.dev/server/v2/contract/11155111/0xD3D65E039fAC0b2924594061BE79E8089A0367d3?fields=match,creationMatch,runtimeMatch)
- Deployment transaction: [`0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793`](https://sepolia.etherscan.io/tx/0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793)
- Initial treasury/holder: `0x71AF09966CBED4434ccA97c40Fa38B8083548B95`

The source in this repository matches the verified Sepolia deployment. Sourcify reports exact
creation and runtime bytecode matches.

## Reproducible compiler settings

- Solidity: `0.8.35+commit.47b9dedd`
- EVM version: `cancun`
- Optimizer: enabled
- Optimizer runs: `200`
- Via IR: disabled
- Metadata bytecode hash: IPFS
- OpenZeppelin Contracts: `v5.6.0`

## Build and test

Install [Foundry](https://book.getfoundry.sh/getting-started/installation), clone with submodules,
then run:

```sh
git clone --recurse-submodules https://github.com/AlexJupiter/new-tibet-coin.git
cd new-tibet-coin
forge build
forge test -vvv
```

## Audit quotation

See [`AUDIT_SCOPE.md`](AUDIT_SCOPE.md) for the proposed review scope, security properties,
deployed test contract and explicitly excluded systems.

The Foundation is separately evaluating on-chain vesting/lockup infrastructure. That mechanism
is not included in this version of the token and must not be assumed to be part of this audit.

## Security warning

Never commit private keys, keystores, RPC credentials or API keys. Deployment secrets must be
provided through a secure local keystore or environment and are intentionally absent here.

## License

MIT
