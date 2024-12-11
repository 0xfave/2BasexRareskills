// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AtomicSwap
 * @author 0xfave
 * @notice A contract that facilitates atomic swaps between NFTs and USDC tokens
 */
contract AtomicSwap {
    using SafeERC20 for IERC20;

    // USDC token interface
    IERC20 public immutable USDC;
    // Price in USDC (2 dollars with 6 decimals)
    uint256 public constant PRICE = 2_000_000;

    event SwapExecuted(
        address indexed nftSender,
        address indexed tokenSender,
        uint256 tokenId,
        address nftContract
    );

    error InsufficientAllowance();
    error TransferFailed();

    constructor(address _usdcAddress) {
        USDC = IERC20(_usdcAddress);
    }

    /**
     * @notice Execute an atomic swap of an NFT for USDC tokens
     * @param _nftContract The address of the NFT contract
     * @param _tokenId The ID of the NFT to be swapped
     * @param _nftSender The address that currently owns the NFT
     * @dev The caller must approve USDC spending and the NFT owner must approve NFT transfer
     */
    function executeSwap(
        address _nftContract,
        uint256 _tokenId,
        address _nftSender
    ) external {
        // Check USDC allowance
        if (USDC.allowance(msg.sender, address(this)) < PRICE) {
            revert InsufficientAllowance();
        }

        // Transfer USDC from caller to NFT sender
        USDC.safeTransferFrom(msg.sender, _nftSender, PRICE);

        // Transfer NFT from sender to caller
        IERC721(_nftContract).transferFrom(_nftSender, msg.sender, _tokenId);

        emit SwapExecuted(_nftSender, msg.sender, _tokenId, _nftContract);
    }
}