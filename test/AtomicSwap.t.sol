// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { AtomicSwap } from "../src/AtomicSwap.sol";
import { USDCERC72Mint } from "../src/USDCERC721Mint.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract AtomicSwapTest is Test {
    AtomicSwap public atomicSwap;
    USDCERC72Mint public nft;
    MockERC20 public usdc;

    address public nftOwner = makeAddr("nftOwner");
    address public usdcHolder = makeAddr("usdcHolder");
    
    uint256 public constant PRICE = 2_000_000; // 2 USDC with 6 decimals
    uint256 public constant NFT_TOKEN_ID = 1;
    string constant NFT_URI = "ipfs://test/";

    error NotOwnerNorApproved();
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    event SwapExecuted(
        address indexed nftSender,
        address indexed tokenSender,
        uint256 tokenId,
        address nftContract
    );

    function setUp() public {
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy NFT contract
        nft = new USDCERC72Mint(
            address(usdc),
            1000, // max supply
            NFT_URI
        );

        // Deploy atomic swap contract
        atomicSwap = new AtomicSwap(address(usdc));

        // Setup NFT owner
        vm.startPrank(nftOwner);
        // Mint USDC to NFT owner for initial mint
        usdc.mint(nftOwner, PRICE);
        usdc.approve(address(nft), PRICE);
        // Mint NFT
        nft.mintWithToken(1);
        // Approve atomic swap contract to transfer NFT
        nft.approve(address(atomicSwap), NFT_TOKEN_ID);
        vm.stopPrank();

        // Setup USDC holder
        vm.startPrank(usdcHolder);
        // Mint USDC to holder
        usdc.mint(usdcHolder, PRICE);
        // Approve atomic swap contract to spend USDC
        usdc.approve(address(atomicSwap), PRICE);
        vm.stopPrank();
    }

    function test_ExecuteSwap() public {
        // Store initial balances and owners
        uint256 initialUSDCHolderBalance = usdc.balanceOf(usdcHolder);
        uint256 initialNFTOwnerBalance = usdc.balanceOf(nftOwner);

        // Execute swap
        vm.prank(usdcHolder);
        
        vm.expectEmit(true, true, true, true);
        emit SwapExecuted(nftOwner, usdcHolder, NFT_TOKEN_ID, address(nft));
        
        atomicSwap.executeSwap(address(nft), NFT_TOKEN_ID, nftOwner);

        // Verify NFT ownership changed
        assertEq(nft.ownerOf(NFT_TOKEN_ID), usdcHolder, "NFT should be transferred to USDC holder");

        // Verify USDC balances
        assertEq(
            usdc.balanceOf(usdcHolder),
            initialUSDCHolderBalance - PRICE,
            "USDC holder balance should decrease by price"
        );
        assertEq(
            usdc.balanceOf(nftOwner),
            initialNFTOwnerBalance + PRICE,
            "NFT owner balance should increase by price"
        );
    }

    function test_RevertWhen_InsufficientAllowance() public {
        // Remove USDC approval
        vm.prank(usdcHolder);
        usdc.approve(address(atomicSwap), 0);

        // Attempt swap
        vm.prank(usdcHolder);
        vm.expectRevert(AtomicSwap.InsufficientAllowance.selector);
        atomicSwap.executeSwap(address(nft), NFT_TOKEN_ID, nftOwner);
    }

    function test_RevertWhen_NFTNotApproved() public {
        // Remove NFT approval
        vm.startPrank(nftOwner);
        nft.approve(address(0), NFT_TOKEN_ID);
        vm.stopPrank();

        // Attempt swap
        vm.prank(usdcHolder);
        vm.expectRevert(NotOwnerNorApproved.selector);
        atomicSwap.executeSwap(address(nft), NFT_TOKEN_ID, nftOwner);
    }

    function test_RevertWhen_InsufficientUSDCBalance() public {
        // Set USDC balance to 0
        vm.startPrank(usdcHolder);
        uint256 balance = usdc.balanceOf(usdcHolder);
        usdc.transfer(nftOwner, balance);

        // Attempt swap with 0 balance
        vm.expectRevert();
        atomicSwap.executeSwap(address(nft), NFT_TOKEN_ID, nftOwner);
        vm.stopPrank();
    }
}
