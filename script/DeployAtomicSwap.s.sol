// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { BaseScript } from "./Base.s.sol";
import { AtomicSwap } from "../src/AtomicSwap.sol";

contract DeployAtomicSwap is BaseScript {
    function run() public returns (AtomicSwap) {
        // USDC token address on Base Sepolia
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        vm.startBroadcast();
        
        AtomicSwap swap = new AtomicSwap(usdcAddress);

        vm.stopBroadcast();

        return swap;
    }
}
