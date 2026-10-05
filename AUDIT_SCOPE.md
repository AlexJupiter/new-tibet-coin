# Audit scope

## Frozen version

The audit handoff is the exact commit referenced by the annotated Git tag
`audit-candidate-v3`. A branch name or the latest `main` commit is not a sufficient scope
identifier. The auditor and Foundation should both record the tag's resolved commit SHA before
work begins.

No Solidity, dependency, compiler or deployment change should be treated as covered unless the
auditor reviews the resulting diff. Audit fixes should be committed separately and submitted for
fix review before a final release tag is created.

| Build property | Audit candidate |
| --- | --- |
| Solidity | `0.8.37` |
| EVM version | `cancun` |
| Optimizer | Enabled, 200 runs |
| Via IR | Disabled |
| OpenZeppelin Contracts | `v5.6.0` (`56a3de2cea907c9a500d32e70c275f68393b7ba6`) |
| forge-std | `v1.11.0` (`8e40513d678f392f398620b3ef2b418648b33e89`) |
| Foundry | `v1.5.1` |

The current candidate symbol is `TIBETLOCKED2`. If the production name or symbol will differ,
that decision should be made before the audit begins or the exact post-audit diff must be accepted
in writing by the auditor.

## In scope

### Deployed and deployment-critical code

- `src/NewTibetCoin.sol`
- `script/DeployNewTibetCoin.s.sol`
- `foundry.toml`, `remappings.txt` and the pinned Git submodules
- The inherited OpenZeppelin v5.6.0 behavior used by `ERC20`, `ERC20Burnable`, `ERC20Permit`,
  `ERC20Votes` and `Nonces`
- Constructor parameters and the production process in `DEPLOYMENT.md`

### Supporting assurance material

- `test/NewTibetCoin.t.sol`
- `test/NewTibetCoin.invariant.t.sol`
- `.github/workflows/ci.yml`
- `slither.config.json`
- `README.md` and `TRANSFER_RESTRICTIONS.md`

## Intended behavior and security properties

1. Exactly 13,000,000,000 tokens are minted once to the constructor-supplied Foundation Safe.
2. The Foundation Safe parameter must contain deployed contract code. Operational checks must
   separately confirm that it is the intended official Safe with the approved configuration.
3. No external mint function, proxy or post-deployment supply expansion exists.
4. Before release, only the Foundation Safe can be the source of a balance reduction. The Safe
   can transfer or burn its own tokens during this phase.
5. Before release, every other holder is blocked from `transfer`, `transferFrom`, `burn` and
   `burnFrom`, including zero-value transfers.
6. Approvals, EIP-2612 permits and vote delegation are allowed while transfers are disabled, but
   neither approvals nor permits can bypass the balance-reduction restriction. Existing allowances
   become usable immediately after release.
7. Only the Foundation Safe can call `enableTransfers()`.
8. Release is global, irreversible and cannot be repeated or paused.
9. After release, standard ERC-20 transfer and burn behavior applies to every holder.
10. The Safe cannot mint, confiscate, rebase, tax, blacklist, pause or reverse release.
11. ERC20Votes voting units and checkpoints must track distributions, transfers and burns.
12. `totalSupply()` can only remain constant or decrease through burning; it can never exceed
    `INITIAL_SUPPLY`.

## Priority review questions

- Can any allowance, permit, voting, burn or inherited OpenZeppelin path bypass the pre-release
  restriction?
- Does the `_update` override compose correctly with both `ERC20` and `ERC20Votes`?
- Can any caller other than the exact immutable Foundation Safe release transfers?
- Can the released state ever return to the locked state?
- Are the constructor validation and deployment checks sufficient to prevent an incorrect treasury
  or non-Safe contract from receiving the complete supply?
- Do the compiler settings, dependency pins and deployment procedure reproduce the reviewed
  bytecode?

## Trust assumptions

- The Foundation Safe's implementation, threshold, owners, modules, guards, fallback handler and
  operational security are reviewed separately.
- The Foundation accepts that its address cannot be replaced in this immutable token.
- The Foundation chooses recipients, amounts and the release time through its Safe process.
- Signers verify the destination, calldata and chain before approving the irreversible release.

## Out of scope

- Individual vesting schedules or recipient-specific locks
- Additional distributor addresses or administrator migration
- The Safe implementation and signer/key security, except for validating the token integration and
  documented deployment assumptions
- Allocation calculations and off-chain recipient data
- Sale, ICO, vesting-provider, staking, rewards, UBI, payment, bridge and wrapped-token contracts
- Front ends, exchange integrations, market design and legal or compliance analysis
- Superseded Sepolia test deployments

Any future contract that holds, sells, vests, stakes, bridges or wraps this token requires its own
security review; this audit scope does not extend automatically to those systems.
