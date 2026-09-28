# New Tibet Coin (`TIBETLOCKED2`)

Minimal fixed-supply ERC-20 with a [New Tibet Foundation](https://newtibet.com/)-controlled, one-way transfer release.

## Contract summary

| Property | Value |
| --- | --- |
| Name | New Tibet Coin |
| Symbol | `TIBETLOCKED2` |
| Decimals | 18 |
| Initial supply | 13,000,000,000 TIBETLOCKED2 |
| Initial holder | Constructor-supplied Foundation Safe |
| Future minting | None |
| Upgradeability | None |
| Extensions | Burnable, EIP-2612 Permit, ERC20Votes |

The project-specific implementation is [`src/NewTibetCoin.sol`](src/NewTibetCoin.sol).
OpenZeppelin Contracts v5.6.0 supplies the standard token behavior.

## Transfer restriction

- Before release, the Foundation Safe can distribute tokens but no other holder can transfer or
  burn them.
- The Foundation Safe can call `enableTransfers()` once.
- Release is global and irreversible.
- There is no owner framework, pause, blacklist, tax, rebase, confiscation, distributor registry,
  individual lock, administrator migration or external mint function.

See [`TRANSFER_RESTRICTIONS.md`](TRANSFER_RESTRICTIONS.md) for the operating sequence and
[`AUDIT_SCOPE.md`](AUDIT_SCOPE.md) for the audit boundary.

## Sepolia test deployment

The current `TIBETLOCKED2` implementation was deployed and exercised on Sepolia on 28 September
2026.

| Property | Value |
| --- | --- |
| Network | Ethereum Sepolia (`11155111`) |
| Token contract | [`0x285f8792392b4D90c10C235BDaF6525eDcB17364`](https://sepolia.etherscan.io/address/0x285f8792392b4D90c10C235BDaF6525eDcB17364#code) |
| Foundation Safe | [`0x407A99ABbd7Ada3456944200d697aF7b0cf5443e`](https://sepolia.etherscan.io/address/0x407A99ABbd7Ada3456944200d697aF7b0cf5443e) |
| Deployment transaction | [`0x49695321...2436998`](https://sepolia.etherscan.io/tx/0x49695321d1a022d6235d481b1ffca66754c834af40ed781a7aa429bfb2436998) |
| Transfer-release transaction | [`0x48728d1b...f232215`](https://sepolia.etherscan.io/tx/0x48728d1bffd374cd74d09e3f373a682463c6e2600f2d8ffe6b4d4c2bcf232215) |
| Source verification | Etherscan verified; Sourcify exact match |
| Current transfer state | Permanently enabled |

The test sequence confirmed that the Foundation Safe could distribute tokens while transfers were
locked, recipient accounts could not transfer or burn, the Safe could release transfers through
its multisig process, and recipient accounts could transfer after release. Because release is
one-way, this particular test deployment cannot be returned to its locked state.

Superseded immutable test contracts:

- `TIBETLOCKED`: [`0x2c669404b2fdbdde12709283BB6170689F2b66e2`](https://sepolia.etherscan.io/address/0x2c669404b2fdbdde12709283BB6170689F2b66e2#code)
- Restricted `TIBET`: [`0x121EDEfc0e2E582D7222CC7e18037b9c8475EF85`](https://sepolia.etherscan.io/address/0x121EDEfc0e2E582D7222CC7e18037b9c8475EF85#code)
- Unrestricted V1: [`0xD3D65E039fAC0b2924594061BE79E8089A0367d3`](https://sepolia.etherscan.io/address/0xD3D65E039fAC0b2924594061BE79E8089A0367d3#code)

## Reproducible build

- Solidity: `0.8.35+commit.47b9dedd`
- EVM version: `cancun`
- Optimizer: enabled, 200 runs
- Via IR: disabled
- Metadata bytecode hash: IPFS

```sh
git clone --recurse-submodules https://github.com/AlexJupiter/new-tibet-coin.git
cd new-tibet-coin
forge fmt --check
forge build --sizes
forge test -vvv
```

## Security warning

Never commit private keys, keystores, RPC credentials or API keys. This code has automated tests
but has not received an external security audit.

## License

MIT
