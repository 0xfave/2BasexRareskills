// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC721 } from "@solady/src/tokens/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LibString } from "@solady/src/utils/g/LibString.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title USDCERC72Mint
 * @author 0xfave
 * @notice An NFT smart contract that accepts USDC Tokens as payment
 */
contract USDCERC72Mint is ERC721, Ownable {
    using SafeERC20 for IERC20;

    // TOKEN_ADDRESS is the accepted ERC20 token used to purchase NFTs
    IERC20 public immutable TOKEN_ADDRESS;
    // @notice NFT max supply
    uint256 public immutable MAX_SUPPLY;
    // @notice NFT mint price
    uint256 public mintPrice = 1e6; // 1 usdc and 6 decimals 1000000
    // @notice NFT uri
    string private _baseURIString;
    uint64 public maxPublicMint;
    uint256 private _totalSupply;

    event FundsWithdrawn();

    error MintExceeded();
    error SupplyExceeded();

    /**
     * @notice Constructor
     * @param _tokenAddress Address of accepted token
     * @param _maxSupply Maximum supply of the NFT
     * @param _uri Base URI of the NFT
     */
    constructor(
        address _tokenAddress,
        uint256 _maxSupply,
        string memory _uri
    )
        Ownable(msg.sender)
    {
        TOKEN_ADDRESS = IERC20(_tokenAddress);
        MAX_SUPPLY = _maxSupply;
        _baseURIString = _uri;
    }

    function name() public override pure returns (string memory) {
        return "USDCERC72Mint";
    }

    function symbol() public override pure returns (string memory) {
        return "UEM";
    }

    function _transferPaymentToken(uint256 _amount) internal {
        TOKEN_ADDRESS.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function mintWithToken(uint256 _amount) external {
        if (_totalSupply + _amount > MAX_SUPPLY) revert SupplyExceeded();
        uint256 mintAmount = mintPrice * _amount;
        _transferPaymentToken(mintAmount);
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, _totalSupply + 1);
            _totalSupply++;
        }
    }

    function updatePrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Set the base URI
    /// @dev Only the owner can call this function
    /// @param _uri Base URI of the NFT
    function setBaseUri(string calldata _uri) external onlyOwner {
        _baseURIString = _uri;
    }

    /// @notice Get the base URI
    /// @return Base URI of the NFT
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURIString;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, LibString.toString(tokenId))) : "";
    }

    /// @notice Withdraw the contract balance
    /// @dev Only the owner can call this function
    function withdrawTokens() external onlyOwner {
        // Checks the contract balance
        IERC20(TOKEN_ADDRESS).safeTransfer(msg.sender, IERC20(TOKEN_ADDRESS).balanceOf(address(this)));

        emit FundsWithdrawn();
    }
}
