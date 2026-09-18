# Audit scope

## In scope

- `src/NewTibetCoin.sol`
- Its composition with OpenZeppelin Contracts v5.6.0:
  - `ERC20`
  - `ERC20Burnable`
  - `ERC20Permit`
  - `ERC20Votes`
  - `Nonces`
- Constructor and deployment assumptions
- Fixed-supply, burning, permit, delegation and checkpoint behavior
- Inheritance resolution in `_update` and `nonces`

## Primary security properties

1. Exactly 13,000,000,000 tokens are minted once during construction.
2. The full initial supply is minted to the non-zero constructor-supplied treasury.
3. No external mint function or post-deployment supply expansion exists.
4. No owner, administrator, proxy, pause, blacklist, tax, rebase or confiscation mechanism exists.
5. Holders may burn their own tokens; approved spenders may burn within allowance.
6. EIP-2612 permit signatures and ERC20Votes delegation/checkpoints behave as intended.
7. Transfers and voting checkpoints remain consistent across mint, transfer and burn operations.

## Out of scope

- Foundation Safe configuration and signer security
- Token allocation, vesting or lockup contracts
- Exchanges, bridges and wrapped versions
- Front ends, off-chain services and legal/compliance analysis
- The deployment script except as it relates to constructor arguments

## Known deployment

- Network: Ethereum Sepolia (`11155111`)
- Contract: `0xD3D65E039fAC0b2924594061BE79E8089A0367d3`
- Deployment transaction: `0xd14532965994fb23e10642719e797d21fa8b80f028f981f0d6bce7b975804793`
- Deployer: `0xE3D3F8465c8FB76F2E5DD8045f9128A1186a40a3`
- Initial treasury/holder: `0x71AF09966CBED4434ccA97c40Fa38B8083548B95`

The deployed source has exact creation-bytecode and runtime-bytecode matches on Sourcify.

## Planned but not included

The Foundation is evaluating third-party on-chain vesting/lockup infrastructure. No lockup or
vesting mechanism is embedded in this token version. Any future change to the token contract
requires a new audit scope and a new deployment because this contract is not upgradeable.
