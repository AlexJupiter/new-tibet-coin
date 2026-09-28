#!/usr/bin/env bash

set -Eeuo pipefail

readonly FOUNDATION_SAFE_ADDRESS="${FOUNDATION_SAFE_ADDRESS:-0x407A99ABbd7Ada3456944200d697aF7b0cf5443e}"
readonly RPC_URL="${SEPOLIA_RPC_URL:-https://ethereum-sepolia-rpc.publicnode.com}"
readonly KEYSTORE_PATH="${KEYSTORE_PATH:-${HOME}/.foundry/keystores/ntc-sepolia-deployer-v2}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
password_file=""

cleanup() {
    if [[ -n "${password_file}" && -f "${password_file}" ]]; then
        rm -f -- "${password_file}"
    fi
    unset DEPLOY_PASSWORD || true
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! -f "${KEYSTORE_PATH}" ]]; then
    printf 'Keystore not found: %s\n' "${KEYSTORE_PATH}" >&2
    exit 1
fi

umask 077
password_file="$(mktemp "${TMPDIR:-/tmp}/ntc-keystore-password.XXXXXX")"

IFS= read -r -s -p "Keystore password: " DEPLOY_PASSWORD
printf '\n'
printf '%s\n' "${DEPLOY_PASSWORD}" > "${password_file}"
unset DEPLOY_PASSWORD

cd "${repo_root}"

FOUNDATION_SAFE_ADDRESS="${FOUNDATION_SAFE_ADDRESS}" forge script \
    script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin \
    --rpc-url "${RPC_URL}" \
    --keystore "${KEYSTORE_PATH}" \
    --password-file "${password_file}" \
    --broadcast
