# Production deployment runbook

This runbook is for the canonical Ethereum mainnet deployment of New Tibet Coin. It is a
two-person operational checklist, not an authorization to deploy. The Foundation must approve the
final audit commit, Safe configuration, deployment parameters and launch timing before any
transaction is broadcast.

The Sepolia helper in `scripts/deploy-sepolia.sh` is test-only and must not be used for mainnet.

## 1. Freeze the release

Before scheduling deployment:

- Resolve all audit findings and obtain the auditor's fix review.
- Decide the final token name and symbol. The current candidate uses `New Tibet Coin` and
  `TIBETLOCKED2`; any production change must be included in the reviewed commit.
- Create a final signed or annotated release tag from the auditor-approved commit.
- Record the resolved commit SHA, submodule SHAs, compiler settings and audit report.
- Confirm that CI, unit tests, fuzz tests, invariant tests and Slither all pass on that commit.
- Do not deploy from a working tree with local or untracked changes.

The deployment manifest must record these final values:

| Parameter | Required value |
| --- | --- |
| Network | Ethereum mainnet |
| Chain ID | `1` |
| Release tag and commit | To be approved after audit fix review |
| Foundation Safe | To be approved and recorded before deployment |
| Safe threshold and owners | To be approved and independently checked |
| Solidity | `0.8.37` |
| EVM version | `cancun` |
| Optimizer | Enabled, 200 runs |
| OpenZeppelin Contracts | `v5.6.0` at the pinned submodule commit |

## 2. Prepare the Foundation Safe

Deploy the intended Safe on Ethereum mainnet before deploying the token. The token constructor
rejects addresses without code, but it cannot prove that a contract is an official or correctly
configured Safe.

Two Foundation representatives must independently verify and record:

- The checksummed Safe address and Ethereum mainnet network.
- The Safe singleton/proxy implementation is an official supported deployment.
- Every owner address and the approval threshold.
- All enabled modules, guards and the fallback handler.
- That no unexpected spending limit, module or queued transaction exists.
- That signers use the Foundation-approved hardware wallets and backup procedure.

The Safe address is immutable in the token. A mistake cannot be repaired or migrated by the token.

## 3. Build from a clean checkout

Replace `FINAL_AUDITOR_APPROVED_TAG` inside the quotation marks with the approved release tag:

```sh
git clone --branch "FINAL_AUDITOR_APPROVED_TAG" --recurse-submodules \
  https://github.com/AlexJupiter/new-tibet-coin.git new-tibet-coin-release
cd new-tibet-coin-release

git status --short
git rev-parse HEAD
git submodule status --recursive
```

`git status --short` must display nothing. The release commit must match the Foundation's approved
deployment record. The five submodule lines must contain these exact commit and folder pairs:

```text
8e40513d678f392f398620b3ef2b418648b33e89 lib/forge-std
56a3de2cea907c9a500d32e70c275f68393b7ba6 lib/openzeppelin-contracts
232ff9ba8194e406967f52ecc5cb52ed764209e9 lib/openzeppelin-contracts/lib/erc4626-tests
3b20d60d14b343ee4f908cb8079495c07f5e8981 lib/openzeppelin-contracts/lib/forge-std
7328abe100445fc53885c21d0e713b95293cf14c lib/openzeppelin-contracts/lib/halmos-cheatcodes
```

Each line must begin with a blank space. Stop if a line begins with `-`, `+` or `U`. Ignore the
descriptive text in parentheses at the end of a line; the commit and folder are authoritative.

Confirm the direct dependency versions:

```sh
git -C lib/openzeppelin-contracts rev-parse HEAD
git -C lib/openzeppelin-contracts tag --points-at HEAD
git -C lib/forge-std rev-parse HEAD
git -C lib/forge-std tag --points-at HEAD
```

The expected direct dependency results are OpenZeppelin commit
`56a3de2cea907c9a500d32e70c275f68393b7ba6` at `v5.6.0` and forge-std commit
`8e40513d678f392f398620b3ef2b418648b33e89` at `v1.11.0`.

Run the following checks one at a time and save their complete output with the deployment manifest:

| Command | Reason | Required result |
| --- | --- | --- |
| `forge --version` | Confirms the reviewed build-tool version. | First line is `forge Version: 1.5.1-stable`. |
| `forge fmt --check` | Detects accidental Solidity formatting changes. | No output and no proposed change. |
| `forge build --sizes` | Compiles with Solidity 0.8.37 and checks Ethereum code-size limits. | Successful build; `NewTibetCoin` shows runtime size `7,929` and creation-code size `10,953` bytes. |
| `forge test -vvv` | Runs unit, fuzz and invariant tests. | 16 token tests and 4 invariant tests pass; none fail or are skipped. |
| `slither . --config-file slither.config.json` | Scans for common Solidity vulnerabilities. | Final message ends with `0 result(s) found`. |

Run the commands:

```sh
forge --version
forge fmt --check
forge build --sizes
forge test -vvv
slither . --config-file slither.config.json
```

The detailed test output must show 1,000 runs for each fuzz test and 256 runs with 16,384 calls for
each invariant. Solidity can print known deprecation warnings for files under `lib/forge-std` and a
style note about the `foundationSafe` name. Stop for any compiler error, failed or skipped test,
Slither finding, or other warning referring to `src/NewTibetCoin.sol`. Passing these checks does not
replace the independent external audit.

## 4. Validate the network and Safe

Use a trusted authenticated Ethereum RPC endpoint. Do not place RPC credentials, private keys,
keystore passwords or explorer API keys in the repository or command history.

```sh
export NTC_MAINNET_RPC_URL="<trusted Ethereum mainnet RPC URL>"
export NTC_FOUNDATION_SAFE="<approved checksummed Foundation Safe address>"

test "$(cast chain-id --rpc-url "$NTC_MAINNET_RPC_URL")" = "1"
test "$(cast code "$NTC_FOUNDATION_SAFE" --rpc-url "$NTC_MAINNET_RPC_URL")" != "0x"
```

Compare `NTC_FOUNDATION_SAFE` against the approved address character by character with a second
person. Inspect the address in both Safe Wallet and a mainnet block explorer.

## 5. Simulate without broadcasting

The deployment script requires the expected chain ID and performs post-deployment assertions for
the immutable Safe, supply, Safe balance and locked transfer state.

```sh
EXPECTED_CHAIN_ID=1 \
FOUNDATION_SAFE_ADDRESS="$NTC_FOUNDATION_SAFE" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "$NTC_MAINNET_RPC_URL" \
  -vvvv
```

Review the simulation with a second person. Confirm the constructor argument, token metadata,
13,000,000,000-token supply and absence of any unexpected call.

## 6. Broadcast once

Use a dedicated deployment account backed by the Foundation-approved signing device or encrypted
Foundry keystore. Fund it only with the ETH reasonably required for deployment. The deployer
receives no token privilege and can be retired afterward.

Example using a named Foundry keystore account:

```sh
EXPECTED_CHAIN_ID=1 \
FOUNDATION_SAFE_ADDRESS="$NTC_FOUNDATION_SAFE" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "$NTC_MAINNET_RPC_URL" \
  --account <approved Foundry account name> \
  --broadcast \
  --slow \
  -vvvv
```

One operator prepares and reads the transaction; a second operator verifies the chain, Safe
constructor argument and expected creation before the signer authorizes it. Record the deployment
transaction hash and contract address immediately.

## 7. Verify source and deployed state

Verify the exact release source on both Etherscan and Sourcify. Constructor arguments are the
ABI-encoded Foundation Safe address.

```sh
export NTC_TOKEN_ADDRESS="<deployed token address>"
export NTC_CONSTRUCTOR_ARGS="$(cast abi-encode 'constructor(address)' "$NTC_FOUNDATION_SAFE")"

forge verify-contract \
  --verifier etherscan \
  --chain mainnet \
  --watch \
  --constructor-args "$NTC_CONSTRUCTOR_ARGS" \
  "$NTC_TOKEN_ADDRESS" \
  src/NewTibetCoin.sol:NewTibetCoin

forge verify-contract \
  --verifier sourcify \
  --chain mainnet \
  --watch \
  --constructor-args "$NTC_CONSTRUCTOR_ARGS" \
  "$NTC_TOKEN_ADDRESS" \
  src/NewTibetCoin.sol:NewTibetCoin
```

Read and independently compare every deployment invariant:

```sh
cast call "$NTC_TOKEN_ADDRESS" 'name()(string)' --rpc-url "$NTC_MAINNET_RPC_URL"
cast call "$NTC_TOKEN_ADDRESS" 'symbol()(string)' --rpc-url "$NTC_MAINNET_RPC_URL"
cast call "$NTC_TOKEN_ADDRESS" 'totalSupply()(uint256)' --rpc-url "$NTC_MAINNET_RPC_URL"
cast call "$NTC_TOKEN_ADDRESS" 'foundationSafe()(address)' --rpc-url "$NTC_MAINNET_RPC_URL"
cast call "$NTC_TOKEN_ADDRESS" 'balanceOf(address)(uint256)' "$NTC_FOUNDATION_SAFE" \
  --rpc-url "$NTC_MAINNET_RPC_URL"
cast call "$NTC_TOKEN_ADDRESS" 'transfersEnabled()(bool)' --rpc-url "$NTC_MAINNET_RPC_URL"
```

Expected results include:

- `totalSupply()` and the Safe balance both equal
  `13000000000000000000000000000` base units.
- `foundationSafe()` equals the approved Safe exactly.
- `transfersEnabled()` is `false`.
- Etherscan's runtime bytecode and constructor arguments match the audited build.

Do not distribute tokens if any check differs. Since the token is immutable, abandon an incorrect
deployment and investigate before deploying a replacement.

## 8. Distribution and irreversible release

Before release:

- Only the Safe may transfer or burn tokens.
- Reconcile every recipient and amount against the approved allocation records.
- Test a recipient's attempted transfer and confirm it reverts with `TransfersDisabled()`.
- Treat allowances and permits as live commitments: they become usable immediately upon release.

To release, the Safe must call the token's `enableTransfers()` function with zero ETH. The calldata
is `0xaf35c6c7`. Every signer must verify the token address, zero value, `CALL` operation and calldata.

The release is global and irreversible. Execute it only after allocations are reconciled, exchange
and communications teams are ready, and the Foundation has completed its approval process.

After execution, record the transaction hash, confirm `transfersEnabled()` returns `true`, and test
ordinary holder transfers. Publish the final contract address, verified source, audit report,
deployment transaction, release transaction and operational contacts.
