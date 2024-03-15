// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title EnumerableNFT
 * @dev A contract for creating an NFT collection with 20 items using ERC721Enumerable.
 */
contract EnumerableNFT is ERC721Enumerable, Ownable2Step {
    uint256 public constant MAX_SUPPLY = 20; // Maximum supply of the NFTs
    uint256 public constant MINT_PRICE = 0.5 ether; // Price for regular minting

    event Minted(address indexed sender, uint256 indexed tokenId);

    // Custom errors
    error InsufficientEther(); // Error for insufficient ether sent
    error MaxSupplyReached(); // Error when maximum supply of NFTs is reached
    error InvalidTokenId(); // Error for invalid token ID

    /**
     * @dev Constructor to initialize the contract with name and symbol, and set the owner.
     */
    constructor() ERC721("Enumerable NFT", "ENFT") Ownable(msg.sender) {}

    /**
     * @dev Function to mint a new NFT with the specified token ID.
     * @param _tokenId The token ID to mint.
     */
    function mint(uint256 _tokenId) external payable {
        if (_tokenId > 100 || _tokenId == 0) {
            // Check if the token ID is within valid range
            revert InvalidTokenId();
        }

        if (totalSupply() >= MAX_SUPPLY) {
            // Check if maximum supply is reached
            revert MaxSupplyReached();
        }

        if (msg.value < MINT_PRICE) {
            // Check if the sent ether is sufficient
            revert InsufficientEther();
        }

        _safeMint(msg.sender, _tokenId); // Mint the NFT to the sender

        emit Minted(msg.sender, _tokenId); // Emit Minted event
    }

    /**
     * @dev Allows the owner to withdraw accumulated ether.
     */
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance); // Transfer ether to owner
    }
}
