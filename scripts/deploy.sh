#!/usr/bin/env bash
# Rehearse the deployment, then request one creation transaction with a fixed gas limit.
set -Eeuo pipefail

: "${RPC_URL:?}" "${DEPLOYER:?}" "${FOUNDATION_SAFE_ADDRESS:?}" "${EXPECTED_CHAIN_ID:?}"
: "${EXPECTED_NONCE:?set the approved deployer nonce}"

stop() { printf 'Stop: %s\n' "$*" >&2; exit 1; }

# Only signer and logging options may vary. Transaction fields are set below.
for argument in "$@"; do
    [[ "$argument" =~ ^(--browser|--ledger|--trezor|-v{1,5})$ ]] ||
        stop "unsupported argument $argument"
done
[[ "$EXPECTED_NONCE" =~ ^(0|[1-9][0-9]*)$ ]] || stop "invalid approved nonce"
cd "$(dirname "${BASH_SOURCE[0]}")/.."

rpc=(--rpc-url "$RPC_URL")
forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin "${rpc[@]}" --sender "$DEPLOYER"

bytecode="$(forge inspect src/NewTibetCoin.sol:NewTibetCoin bytecode)"
[[ "$bytecode" =~ ^0x([[:xdigit:]]{2})+$ ]] || stop "invalid creation bytecode"
constructor="$(cast abi-encode 'constructor(address)' "$FOUNDATION_SAFE_ADDRESS")"
[[ "$constructor" =~ ^0x[[:xdigit:]]{64}$ ]] || stop "invalid constructor encoding"
initcode="$bytecode${constructor#0x}"
creation=(--from "$DEPLOYER" --nonce "$EXPECTED_NONCE")

estimate="$(cast estimate "${rpc[@]}" "${creation[@]}" --create "$initcode")"
[[ "$estimate" =~ ^[1-9][0-9]{0,11}$ ]] || stop "invalid target-network gas estimate"
gas_limit=$(( (estimate * 115 + 99) / 100 ))
printf 'Network gas estimate: %s\nGas limit to sign:    %s\n' "$estimate" "$gas_limit"
(( gas_limit <= 16777216 )) || stop "required gas limit exceeds 16,777,216"

latest="$(cast nonce "$DEPLOYER" --block latest "${rpc[@]}")"
pending="$(cast nonce "$DEPLOYER" --block pending "${rpc[@]}")"
[[ "$latest" == "$EXPECTED_NONCE" && "$pending" == "$EXPECTED_NONCE" ]] ||
    stop "latest and pending deployer nonces must both equal $EXPECTED_NONCE"

exec cast send "${rpc[@]}" --chain "$EXPECTED_CHAIN_ID" "${creation[@]}" "$@" --gas-limit "$gas_limit" --create "$initcode"
