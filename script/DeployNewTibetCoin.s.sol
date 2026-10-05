// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import { Script } from "forge-std/Script.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract DeployNewTibetCoin is Script {
    error DeploymentInvariantFailed();
    error UnexpectedChain(uint256 expected, uint256 actual);

    function run() external returns (NewTibetCoin token) {
        uint256 expectedChainId = vm.envUint("EXPECTED_CHAIN_ID");
        address foundationSafe = vm.envAddress("FOUNDATION_SAFE_ADDRESS");

        if (block.chainid != expectedChainId) {
            revert UnexpectedChain(expectedChainId, block.chainid);
        }

        vm.startBroadcast();
        token = new NewTibetCoin(foundationSafe);
        vm.stopBroadcast();

        if (
            token.foundationSafe() != foundationSafe
                || token.totalSupply() != token.INITIAL_SUPPLY()
                || token.balanceOf(foundationSafe) != token.INITIAL_SUPPLY()
                || token.transfersEnabled()
        ) {
            revert DeploymentInvariantFailed();
        }
    }
}
