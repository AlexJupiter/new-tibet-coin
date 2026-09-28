// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { Script } from "forge-std/Script.sol";
import { NewTibetCoin } from "../src/NewTibetCoin.sol";

contract DeployNewTibetCoin is Script {
    function run() external returns (NewTibetCoin token) {
        address foundationSafe = vm.envAddress("FOUNDATION_SAFE_ADDRESS");

        vm.startBroadcast();
        token = new NewTibetCoin(foundationSafe);
        vm.stopBroadcast();
    }
}
