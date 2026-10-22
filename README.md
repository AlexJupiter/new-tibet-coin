# New Tibet Coin (`TIBETTEST1`)

Minimal fixed-supply ERC-20 with a [New Tibet Foundation](https://newtibet.com/)-controlled, one-way transfer release.

## Contract summary

| Property | Value |
| --- | --- |
| Name | New Tibet Coin |
| Symbol | `TIBETTEST1` (test symbol; the final mainnet symbol remains subject to Foundation approval and audit) |
| Decimals | 18 |
| Initial supply | 13,000,000,000 TIBETTEST1 |
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

## Sepolia `TIBETTEST1` test deployment

This procedure deploys the current `TIBETTEST1` test contract to Ethereum Sepolia. It is separate
from the production procedure below. Do not use `audit-candidate-v9` for this test because that
immutable tag contains the earlier `TIBETLOCKED2` contract.

Text inside `<ANGLE BRACKETS>` is a placeholder. Replace the entire placeholder with the real
value, while keeping quotation marks where shown. Run each command separately and stop if its
result differs from the stated expectation.

### 1. Check out and test the correct code

Clone the current `main` branch after the `TIBETTEST1` change has been merged:

```sh
git clone --branch main --recurse-submodules https://github.com/AlexJupiter/new-tibet-coin.git new-tibet-coin-sepolia
cd new-tibet-coin-sepolia
```

Confirm that the checkout is clean and record its exact commit:

```sh
git status --short
git rev-parse HEAD
git submodule status --recursive
```

`git status --short` must display nothing. Save the commit printed by `git rev-parse HEAD` with
the test-deployment record. The submodule command must list initialized dependencies and no line
may begin with `-`, `+` or `U`.

Confirm that both the contract and test expect the new symbol:

```sh
grep -n 'TIBETTEST1' src/NewTibetCoin.sol test/NewTibetCoin.t.sol
```

The output must contain the constructor symbol in `src/NewTibetCoin.sol` and the matching symbol
assertion in `test/NewTibetCoin.t.sol`. Stop if either file still contains `TIBETLOCKED2`.

Run all build and security checks:

```sh
forge --version
forge fmt --check
forge build --sizes
forge test -vvv
slither . --config-file slither.config.json
```

`forge test -vvv` must finish with 16 passing unit/fuzz tests and four passing invariant tests,
with no failures or skipped tests. Slither must finish with `0 result(s) found`. Stop for any
compiler error, failed test or Slither finding.

### 2. Confirm Sepolia and the test Foundation Safe

Use this Sepolia RPC for the following commands:

```text
https://ethereum-sepolia-rpc.publicnode.com
```

Confirm the network:

```sh
cast chain-id --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

The result must be `11155111`. Any other number means the terminal is connected to the wrong
network.

Confirm that the Sepolia Foundation Safe contains contract code:

```sh
cast code "0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

The result must be a long hexadecimal value, not only `0x`.

Confirm the Safe owners and threshold:

```sh
cast call "0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" 'getOwners()(address[])' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" 'getThreshold()(uint256)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

The current training Safe should return the three approved test owners and threshold `2`. Check
the same network, address, owners and threshold in the Safe interface before continuing.

### 3. Simulate without deploying

This runs the complete deployment locally against Sepolia without publishing a transaction:

```sh
EXPECTED_CHAIN_ID=11155111 \
FOUNDATION_SAFE_ADDRESS="0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  -vvvv
```

The simulation must complete successfully without broadcasting. Stop if it reports the wrong
chain, rejects the Safe, or fails any post-deployment assertion.

### 4. Deploy through MetaMask and the hardware wallet

Connect the approved test hardware-wallet account to MetaMask, select Sepolia, and confirm that
the deployer has enough Sepolia ETH for the fee. Do not import its recovery phrase or private key.

Record the deployer's pending nonce:

```sh
cast nonce "<SEPOLIA DEPLOYER ADDRESS>" --block pending \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

Use the returned number to calculate the expected token address:

```sh
cast compute-address "<SEPOLIA DEPLOYER ADDRESS>" --nonce <NONCE>
```

Do not send another transaction from the deployer before deployment. Then broadcast once:

```sh
EXPECTED_CHAIN_ID=11155111 \
FOUNDATION_SAFE_ADDRESS="0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --browser \
  --sender "<SEPOLIA DEPLOYER ADDRESS>" \
  --broadcast \
  --slow \
  -vvvv
```

Foundry should open its browser signer. Connect MetaMask, verify Sepolia, the deployer, zero ETH
value and the fee, then approve with the hardware wallet. Save the transaction hash and deployed
contract address. The deployed address must equal the address calculated from the nonce.

### 5. Verify the Sepolia source and bytecode

Encode the Safe constructor argument:

```sh
cast abi-encode 'constructor(address)' "0x407A99ABbd7Ada3456944200d697aF7b0cf5443e"
```

Copy the result and replace `<ENCODED SAFE VALUE>` below:

```sh
forge verify-contract \
  --verifier etherscan \
  --etherscan-api-key "<ETHERSCAN API KEY>" \
  --chain sepolia \
  --watch \
  --constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin

forge verify-contract \
  --verifier sourcify \
  --chain sepolia \
  --watch \
  --constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin

forge verify-bytecode \
  --verifier etherscan \
  --etherscan-api-key "<ETHERSCAN API KEY>" \
  --chain sepolia \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --encoded-constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin
```

Both source-verification services should report a match, and `forge verify-bytecode` must confirm
that the creation and runtime bytecode match the checked-out source.

### 6. Confirm the deployed state

Run each call against the newly deployed token:

```sh
cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'name()(string)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'symbol()(string)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'totalSupply()(uint256)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'foundationSafe()(address)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'balanceOf(address)(uint256)' \
  "0x407A99ABbd7Ada3456944200d697aF7b0cf5443e" \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

cast call "<DEPLOYED TOKEN CONTRACT ADDRESS>" 'transfersEnabled()(bool)' \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

The expected results are:

- Name: `New Tibet Coin`
- Symbol: `TIBETTEST1`
- Total supply: `13000000000000000000000000000`
- Foundation Safe: `0x407A99ABbd7Ada3456944200d697aF7b0cf5443e`
- Safe balance: `13000000000000000000000000000` before any distribution
- Transfers enabled: `false`

Stop and abandon the test deployment if any immutable value is wrong.

### 7. Test the one-way transfer release

1. From the Sepolia Safe, send a small number of tokens to a test account.
2. From that account, attempt to transfer tokens to a second account. The transaction must fail
   while `transfersEnabled()` is `false`.
3. In the Safe Transaction Builder, enter the deployed token address and select
   `enableTransfers()` with no arguments.
4. Obtain the required Safe approvals and execute the transaction.
5. Confirm that `transfersEnabled()` now returns `true`.
6. Repeat the test-account transfer. It must now succeed.

`enableTransfers()` is irreversible, even on Sepolia. Record the deployment transaction, contract
address, commit SHA, deployer, Safe, source-verification links, failed locked-transfer attempt,
release transaction and successful post-release transfer. Add the completed deployment to the
historical Sepolia table later in this README.


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
git clone --branch audit-candidate-v9 --recurse-submodules \
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

#### Confirm the RPC network

This check prevents deployment to the wrong blockchain. Replace the placeholder with the RPC URL
that will be used for deployment:

```sh
cast chain-id --rpc-url "<RPC URL FOR INTENDED NETWORK>"
```

The command prints the network's numerical chain ID and nothing else. Expected results are:

```text
Ethereum mainnet: 1
Sepolia testing:  11155111
```

Your Sepolia test output should therefore be:

```text
11155111
```

For a production deployment, the result must be `1`. A result of `11155111` is correct only during
Sepolia testing. Stop if the result does not match the intended network.

#### Confirm that the Safe address contains a contract

Use the Foundation Safe address from the same network as the RPC:

```sh
cast code "<SAFE ADDRESS ON INTENDED NETWORK>" \
  --rpc-url "<RPC URL FOR INTENDED NETWORK>"
```

This reads the executable contract code stored at that address. A normal Safe proxy produces a long
hexadecimal value beginning with `0x`, for example:

```text
0x6080604052...<many more characters>
```

The exact long value does not need to match this shortened example. A result containing only `0x`
means there is no contract at the address: it may be an ordinary wallet, a mistyped address or an
address from the wrong network. Stop if the result is `0x`, empty, or an error.

The token constructor performs this same basic code-presence check. A long result proves only that
some contract exists; it does not prove that the contract is the official Foundation Safe or that
its security settings are correct.

#### Confirm the Safe owners and approval threshold

Run:

```sh
cast call "<SAFE ADDRESS ON INTENDED NETWORK>" 'getOwners()(address[])' \
  --rpc-url "<RPC URL FOR INTENDED NETWORK>"

cast call "<SAFE ADDRESS ON INTENDED NETWORK>" 'getThreshold()(uint256)' \
  --rpc-url "<RPC URL FOR INTENDED NETWORK>"
```

The first command must return exactly the owner addresses approved by the Foundation. The planned
initial production Safe is 3-of-5, so it must return five approved addresses. The second command
must return `3`. The current Sepolia training Safe is 2-of-3, so three owner addresses and a
threshold of `2` are expected when testing that Safe. Its current expected output is:

```text
[0x71AF09966CBED4434ccA97c40Fa38B8083548B95,
 0x3bffB10F6F17F15164Fbc0416f1Bc42C56b2C191,
 0x548F3D5c4Ebf4A403ae57c2b427AcbE103872EBb]
2
```

Two people must compare every owner and the Safe address character by character with the approved
record. In the official Safe interface, also confirm the same network, owners and threshold, and
confirm that no unexpected module, guard or spending permission is enabled. Stop if any value or
setting differs.

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

The deployment transaction must be signed by the deployer account. The blockchain records the
deployer address and signature, but it cannot reveal or prove whether the signature came from a
Ledger, Trezor or software wallet. Hardware-wallet compliance is therefore an off-chain Foundation
process, not an onchain check.

Connect the approved Ledger or Trezor to MetaMask before running the command:

1. In MetaMask, choose the option to add or connect a hardware-wallet account. Do not import the
   hardware wallet's recovery phrase or private key.
2. Select the exact Foundation-approved deployer address and connect it to MetaMask.
3. Select the intended Ethereum network in MetaMask and compare its chain and selected account with
   the deployment record.
4. Keep the device connected and unlocked. Close any other wallet application that may try to use
   the same device.

The command uses Foundry's `--browser` interface. Foundry opens a local browser page and asks
MetaMask to connect. MetaMask then passes the signing request to the connected hardware wallet.
This avoids Foundry's unreliable direct `--ledger` and `--trezor` interfaces while keeping the
private key inside the hardware wallet.

The deployer should hold only enough ETH for the network fee. It receives no tokens and has no
authority over the token after deployment.

Immediately before broadcasting, record the deployer's pending nonce:

```sh
cast nonce "<HARDWARE-WALLET DEPLOYER ADDRESS>" --block pending \
  --rpc-url "<ETHEREUM MAINNET RPC URL>"
```

The output is a number such as `0`. Use that exact number to calculate the contract address that
this deployment should create:

```sh
cast compute-address "<HARDWARE-WALLET DEPLOYER ADDRESS>" --nonce <NONCE FROM PREVIOUS COMMAND>
```

Record the resulting address. Do not send any other transaction from the deployer between this
check and the deployment, because another transaction would consume the recorded nonce and change
the expected contract address.

```sh
EXPECTED_CHAIN_ID=1 \
FOUNDATION_SAFE_ADDRESS="<FOUNDATION SAFE ADDRESS>" \
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
  --rpc-url "<ETHEREUM MAINNET RPC URL>" \
  --browser \
  --sender "<HARDWARE-WALLET DEPLOYER ADDRESS>" \
  --broadcast \
  --slow \
  -vvvv
```

The important options mean:

| Option | Meaning |
| --- | --- |
| `--browser` | Opens Foundry's local browser signer so the connected MetaMask account can sign. MetaMask must already be connected to the approved hardware wallet. |
| `--sender` | Identifies the public deployer address. It does not reveal a private key. |
| `--broadcast` | Sends the simulated deployment transaction to Ethereum. Without this option, nothing is published. |
| `--slow` | Waits for confirmation instead of submitting later transactions in parallel. |
| `-vvvv` | Displays detailed logs for the deployment record and troubleshooting. |

Foundry should open a local browser page. Connect MetaMask, confirm that its selected account is the
recorded deployer and approve the request in MetaMask. MetaMask should describe the request as a
contract deployment with zero ETH value. Check the selected network, deployer, ETH value and
maximum fee before continuing.

The hardware-wallet screen may then display many pages of raw contract-creation bytecode. That
bytecode is not realistically human-verifiable on the small device screen. Do not treat scrolling
through it as a meaningful source-code review. The hardware wallet protects the signing key and
confirms that its account authorized the exact bytes; the following controls establish what those
bytes are intended to do:

- deploy only from the clean, auditor-approved release checked in Step 1;
- pass every build, test and Slither check and review the no-broadcast simulation;
- have a second person verify the network, Safe, deployer, expected contract address, zero ETH value
  and reasonable maximum fee before device approval; and
- verify the mined bytecode, published source and complete contract state before the Foundation
  recognises the deployment or distributes any tokens.

The device may still require approval of every bytecode screen. Complete those prompts only after
the checks above pass. Foundry should then display a successful transaction hash and the new token
contract address. The new address must equal the address calculated from the deployer nonce. Stop
if it differs or if Foundry reports a failure. Save both addresses and the transaction hash. The
calculated address confirms the deployer and nonce, but the post-deployment checks prove which code
and constructor state were actually deployed.

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

forge verify-bytecode \
  --verifier etherscan \
  --etherscan-api-key "<ETHERSCAN API KEY>" \
  --chain mainnet \
  --rpc-url "<ETHEREUM MAINNET RPC URL>" \
  --encoded-constructor-args "<ENCODED SAFE VALUE>" \
  "<DEPLOYED TOKEN CONTRACT ADDRESS>" \
  src/NewTibetCoin.sol:NewTibetCoin
```

The two source-verification commands must report success, and Sourcify should report an exact match.
`forge verify-bytecode` must confirm that both the creation and runtime bytecode match the reviewed
source and encoded Safe constructor argument. This is the practical check for the raw bytecode that
could not be read meaningfully on the hardware-wallet screen.

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

## Checking Disabled Transfers / Enabling transfers
After a test deployment, it's important to check that token transfers are disabled. The easiest way to do this is to distribute some of the ERC-20 from the test multi-sig to a different account. From this other account, then try and send this ERC-20 token to another other account and you should receive an error and it to be impossible to transfer the token elsewhere. 

Then it's important in the test deployment to check that the transfers can be enabled at a later date. This feature was developed to enable distribution of tokens to team members and investors before the ICO date. To simulate the Foundation's actions on ICO date:
1. Go the the Safe UI for the multi-sig used for testing purposes
2. Head to "New Transaction" in the top left
3. Choose "Transaction Builder" at the bottom
4. Input the ERC-20 contract address that was just deployed
5. Choose the method "enableTransfers" <img width="1780" height="1136" alt="image" src="https://github.com/user-attachments/assets/8fbdacd5-bc33-49f5-956c-8a0886be3517" />
6. Execute the transaction
7. Try again to send the ERC-20 token, from an account other than the test multi-sig, to a new address and you should be able to

## Previous Sepolia test deployment

The previous `TIBETLOCKED2` implementation was deployed and exercised on Sepolia on 28 September
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
