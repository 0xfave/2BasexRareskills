// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { BaseScript } from "./Base.s.sol";
import {USDCERC72Mint} from "../src/USDCERC721Mint.sol";

contract DeployUSDCERC721Mint is BaseScript {
    function run() public returns (USDCERC72Mint) {
        address tokenAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        uint256 maxSupply = 1000; // Adjust this value as needed
        string memory baseURI = "ipfs://your-base-uri/"; // Replace with your actual base URI

        vm.startBroadcast();
        
        USDCERC72Mint nft = new USDCERC72Mint(
            tokenAddress,
            maxSupply,
            baseURI
        );

        vm.stopBroadcast();

        return nft;
    }
}
