// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { BaseScript } from "./Base.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {USDCERC72Mint} from "../src/USDCERC721Mint.sol";

contract MintNFT is BaseScript {
    function run() public {
        // Replace with your deployed NFT contract address
        address nftAddress = 0x5838b115E1798A66D4f25e9622aA2f4a9F82e2A6;
        
        // USDC token address
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        
        // Number of NFTs to mint
        uint256 amount = 1;

        USDCERC72Mint nft = USDCERC72Mint(nftAddress);
        IERC20 usdc = IERC20(usdcAddress);

        // Get the total cost (mintPrice * amount)
        uint256 totalCost = nft.mintPrice() * amount;

        vm.startBroadcast();
        
        // First approve the NFT contract to spend our USDC
        usdc.approve(address(nft), totalCost); // totalCost is already mintPrice (1e6) * amount
        
        // Then mint the NFT
        nft.mintWithToken(amount);

        vm.stopBroadcast();
    }
}
