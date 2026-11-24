#!/usr/bin/env bash
#
# Broadcasts the deployment only if the gas limit that will be signed is at least 115% of a
# fresh target-network estimate for the same creation transaction (audit finding NTF-01-001).
#
# Requires RPC_URL, DEPLOYER, EXPECTED_CHAIN_ID and FOUNDATION_SAFE_ADDRESS.
# Arguments are passed to the broadcast, for example: scripts/deploy.sh --browser -vvvv

set -Eeuo pipefail

readonly MARGIN_PERCENT=115
readonly GAS_CAP=16777216 # EIP-7825 per-transaction limit

: "${RPC_URL:?}" "${DEPLOYER:?}" "${EXPECTED_CHAIN_ID:?}" "${FOUNDATION_SAFE_ADDRESS:?}"
export EXPECTED_CHAIN_ID FOUNDATION_SAFE_ADDRESS

cd "$(dirname "${BASH_SOURCE[0]}")/.."

deploy=(
    forge script script/DeployNewTibetCoin.s.sol:DeployNewTibetCoin
    --rpc-url "${RPC_URL}"
    --sender "${DEPLOYER}"
    --gas-estimate-multiplier "${GAS_ESTIMATE_MULTIPLIER:-800}"
)

# The simulation prints the gas limit Foundry will ask the deployer to sign.
limit="$("${deploy[@]}" | awk '/Estimated total gas used for script/ { print $NF }')"

# eth_estimateGas on the target network for the exact creation transaction.
estimate="$(cast estimate --rpc-url "${RPC_URL}" --from "${DEPLOYER}" \
    --create "$(forge inspect NewTibetCoin bytecode)" \
    'constructor(address)' "${FOUNDATION_SAFE_ADDRESS}")"

printf 'Network gas estimate: %s\nGas limit to sign:    %s\n' "${estimate}" "${limit}"

if ! ((estimate > 0 && limit * 100 >= estimate * MARGIN_PERCENT && limit <= GAS_CAP)); then
    printf 'Stop: the gas limit must be %s%% of the estimate or more, and at most %s.\n' \
        "${MARGIN_PERCENT}" "${GAS_CAP}" >&2
    exit 1
fi

exec "${deploy[@]}" --broadcast --slow "$@"
