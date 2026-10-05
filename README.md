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
The production launch procedure is documented in [`DEPLOYMENT.md`](DEPLOYMENT.md).

## Production deployment

Do not deploy the current candidate to Ethereum mainnet until the external audit is complete, the
auditor has reviewed any fixes, and the Foundation has approved the final name, symbol, Safe and
release tag. Two people should perform and independently check the steps below. The complete
operational checklist is in [`DEPLOYMENT.md`](DEPLOYMENT.md).

In the commands below, text inside `<ANGLE BRACKETS>` is a placeholder. Replace the entire
placeholder with the real value but keep the quotation marks. Run each command separately and check
its result before continuing.

### Suggested RPC endpoints

An RPC endpoint connects the deployment commands to Ethereum. It never needs the deployer's private
key or recovery phrase.

For production, use a private, authenticated mainnet endpoint owned by the Foundation. Do not use a
shared public RPC to broadcast the production deployment. Create a dedicated provider project, keep
its API key out of the repository and have a second provider available for independent checks.

| Network and use | Provider | RPC URL |
| --- | --- | --- |
| Mainnet production | [Alchemy](https://www.alchemy.com/docs/reference/node-supported-chains) | `https://eth-mainnet.g.alchemy.com/v2/<ALCHEMY API KEY>` |
| Mainnet production alternative | [Infura](https://docs.metamask.io/metamask-connect/evm/guides/manage-networks/) | `https://mainnet.infura.io/v3/<INFURA API KEY>` |
| Mainnet read-only cross-check | [PublicNode](https://ethereum.publicnode.com/) | `https://ethereum-rpc.publicnode.com` |
| Sepolia testing, no account required | [PublicNode](https://ethereum.publicnode.com/) | `https://ethereum-sepolia-rpc.publicnode.com` |
| Sepolia testing with a private endpoint | [Alchemy](https://www.alchemy.com/docs/reference/node-supported-chains) | `https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY API KEY>` |
| Sepolia testing alternative | [Infura](https://docs.metamask.io/metamask-connect/evm/guides/manage-networks/) | `https://sepolia.infura.io/v3/<INFURA API KEY>` |

The repository's Sepolia deployment helper uses the PublicNode Sepolia endpoint by default. Confirm
any RPC before using it:

```sh
cast chain-id --rpc-url "https://ethereum-rpc.publicnode.com"
cast chain-id --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

The first command must return `1` for Ethereum mainnet. The second must return `11155111` for
Sepolia. Never continue if the reported chain ID is different from the intended network.

### 1. Check out the approved release

```sh
git clone --branch audit-candidate-v7 --recurse-submodules \
  https://github.com/AlexJupiter/new-tibet-coin.git new-tibet-coin-release

cd new-tibet-coin-release

git status --short
git rev-parse HEAD
git submodule status --recursive
```

`git status --short` must display nothing. Record the commit displayed by `git rev-parse HEAD` and
compare it with the commit shown for the approved GitHub tag.

The five lines from `git submodule status --recursive` must contain these exact commit and folder
pairs:

```text
8e40513d678f392f398620b3ef2b418648b33e89 lib/forge-std
56a3de2cea907c9a500d32e70c275f68393b7ba6 lib/openzeppelin-contracts
232ff9ba8194e406967f52ecc5cb52ed764209e9 lib/openzeppelin-contracts/lib/erc4626-tests
3b20d60d14b343ee4f908cb8079495c07f5e8981 lib/openzeppelin-contracts/lib/forge-std
7328abe100445fc53885c21d0e713b95293cf14c lib/openzeppelin-contracts/lib/halmos-cheatcodes
```

Each output line must begin with a blank space. Stop if a line begins with `-`, `+` or `U`. Text in
parentheses at the end of a line is only Git's descriptive label and can be ignored.

Run these commands to confirm the two direct dependency versions explicitly:

```sh
git -C lib/openzeppelin-contracts rev-parse HEAD
git -C lib/openzeppelin-contracts tag --points-at HEAD
git -C lib/forge-std rev-parse HEAD
git -C lib/forge-std tag --points-at HEAD
```

They must display, in the same order:

```text
56a3de2cea907c9a500d32e70c275f68393b7ba6
v5.6.0
8e40513d678f392f398620b3ef2b418648b33e89
v1.11.0
```

Only continue when every value matches. Then run each build and security check separately.

#### Confirm the Foundry version

```sh
forge --version
```

This proves that the deployment uses the Foundry version fixed in the audit configuration. The
first output line must be:

```text
forge Version: 1.5.1-stable
```

Stop if the version is different.

#### Check Solidity formatting

```sh
forge fmt --check
```

This proves that the Solidity files have the reviewed formatting and have not been accidentally
edited. Success normally produces no output and returns to the terminal prompt. Stop if it displays
a proposed formatting change or an error.

#### Compile the contracts and check their sizes

```sh
forge build --sizes
```

This compiles the token using Solidity `0.8.37` and displays the deployed and creation-code sizes.
The output must report a successful compiler run and include this `NewTibetCoin` row:

```text
NewTibetCoin | 7,929 | 10,953 | 16,647 | 38,199
```

The four numbers are runtime size, creation-code size and their remaining limits, in bytes. They
show that the contract is below Ethereum's size limits. A repeated build can instead say that no
files changed and compilation was skipped; the size table must still appear.

Solidity can print deprecation warnings for files under `lib/forge-std` and a style note suggesting
that `foundationSafe` use capital letters. Those known dependency and naming messages do not change
the contract. Stop for any compiler error or any other warning referring to `src/NewTibetCoin.sol`.

#### Run all automated tests

```sh
forge test -vvv
```

This runs the unit, permit, voting, burn, fuzz and stateful invariant tests. The final summary must
show exactly:

```text
NewTibetCoinInvariantTest | 4 | 0 | 0
NewTibetCoinTest          | 16 | 0 | 0
```

The columns mean passed, failed and skipped. The detailed output must also show 1,000 runs for each
fuzz test and 256 runs with 16,384 calls for each invariant. Stop if any test fails or is skipped.

#### Run Slither security analysis

```sh
slither . --config-file slither.config.json
```

This scans the contracts for common Solidity vulnerabilities and unsafe patterns. The final line
must end with `0 result(s) found`. Stop and investigate if Slither reports any result or error.

Save the output from all five checks with the deployment record. Passing these automated checks is
required, but it does not replace the independent external audit.

Every later command must be run from inside the `new-tibet-coin-release` folder.

### 2. Check the network and Foundation Safe

Check the network. Replace the placeholder with the Foundation's trusted Ethereum mainnet RPC URL:

```sh
cast chain-id --rpc-url "<ETHEREUM MAINNET RPC URL>"
```

The result must be `1`. Any other result means the terminal is connected to the wrong network.

Check that a contract exists at the approved Foundation Safe address:

```sh
cast code "<FOUNDATION SAFE ADDRESS>" --rpc-url "<ETHEREUM MAINNET RPC URL>"
```

The result must be a long value rather than only `0x`. Two people must compare the Safe address
character by character with the Foundation's approved record. Also confirm its owners, threshold,
modules, guards and fallback handler in the official Safe interface.

### 3. Simulate the deployment

This performs a complete rehearsal without publishing a transaction. The first two lines give the
script the only acceptable network (`1` means Ethereum mainnet) and the approved Safe address. They
apply only to this one command.

```sh
EXPECTED_CHAIN_ID=1 \
FOUNDATION_SAFE_ADDRESS="<FOUNDATION SAFE ADDRESS>" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "<ETHEREUM MAINNET RPC URL>" \
  -vvvv
```

Review the output with the second checker. Confirm the network, Safe address, token name, symbol and
13,000,000,000-token supply before continuing.

### 4. Broadcast the deployment once

The deployer must be an approved hardware-wallet account funded only with enough ETH for the
deployment fee. It receives no tokens or authority over the token. The example below uses a Ledger;
use `--trezor` instead of `--ledger` if the approved device is a Trezor.

```sh
EXPECTED_CHAIN_ID=1 \
FOUNDATION_SAFE_ADDRESS="<FOUNDATION SAFE ADDRESS>" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "<ETHEREUM MAINNET RPC URL>" \
  --ledger \
  --sender "<HARDWARE-WALLET DEPLOYER ADDRESS>" \
  --broadcast \
  --slow \
  -vvvv
```

Verify the transaction details on the hardware-wallet screen before approving them. Save the
resulting deployment transaction hash and token contract address.

### 5. Verify the published source

First encode the Foundation Safe address:

```sh
cast abi-encode 'constructor(address)' "<FOUNDATION SAFE ADDRESS>"
```

Copy the value displayed by that command. Paste it into `<ENCODED SAFE VALUE>` below. Verify the
source on both Etherscan and Sourcify. Obtain the Etherscan API key through the Foundation's approved
credential process and do not save it in this repository or shared deployment records.

```sh
forge verify-contract \
  --verifier etherscan \
  --etherscan-api-key "<ETHERSCAN API KEY>" \
  --chain mainnet \
  --watch \
  --constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin

forge verify-contract \
  --verifier sourcify \
  --chain mainnet \
  --watch \
  --constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin
```

### 6. Confirm the deployed state

```sh
cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'name()(string)' \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'symbol()(string)' \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'totalSupply()(uint256)' \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'foundationSafe()(address)' \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'balanceOf(address)(uint256)' \
  "<FOUNDATION SAFE ADDRESS>" \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'transfersEnabled()(bool)' \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"
```

The total supply and Safe balance must both be `13000000000000000000000000000` base units,
`foundationSafe()` must be the approved Safe, and `transfersEnabled()` must be `false`. Do not
distribute tokens or announce the address if any result differs. An incorrect immutable deployment
must be abandoned and investigated.

Deployment does not enable transfers. The Foundation Safe should call `enableTransfers()` only after
allocations and launch preparations are complete. This later action is global and irreversible.

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

- Solidity: `0.8.37+commit.f401782d`
- EVM version: `cancun`
- Optimizer: enabled, 200 runs
- Via IR: disabled
- Metadata bytecode hash: IPFS
- Foundry: `v1.5.1`
- Slither: `0.11.6`

```sh
git clone --recurse-submodules https://github.com/AlexJupiter/new-tibet-coin.git
cd new-tibet-coin
forge fmt --check
forge build --sizes
forge test -vvv
forge coverage --report summary --no-match-coverage "(script|test)/"
slither . --config-file slither.config.json
```

The current unit, fuzz and invariant suites reach 100% line, statement, branch and function
coverage for `src/NewTibetCoin.sol`.

## Security warning

Never commit private keys, keystores, RPC credentials or API keys. This code has automated tests
but has not received an external security audit.

## License

MIT
