// SPDX-License-Identifier: MIT
/**
 * @title MerkleWhitelistNFT
 * @dev The ERC721 NFT with merkle tree discount, include ERC2918 royalty. Addresses in a merkle tree can mint NFTs at a discount
 */
pragma solidity >= 0.6.0 < 0.9.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

// single leaf node represents a single wallet address in our whitelist.

contract MerkleWhitelistNFT is ERC721, ERC2981, Ownable2Step {
    bytes32 public immutable merkleRoot; // Merkle root hash of the whitelist
    uint256 public constant MAX_SUPPLY = 1000; // Maximum supply of the NFTs
    uint256 public constant MINT_PRICE = 0.5 ether; // Price for regular minting
    uint256 public constant WHITELIST_MINT_PRICE = 0.25 ether; // Price for whitelist minting
    uint96 private constant DEFAULT_ROYALTY = 250; // Default royalty percentage (2.5%)
    uint256 public totalSupply; // Total number of NFTs minted
    BitMaps.BitMap private _bitmap; // Bit map to track whitelisted addresses

    event Minted(address indexed sender, uint256 indexed tokenId); // Event emitted upon successful minting
    event Burn(address indexed sender, uint256 indexed tokenId); // Event emitted upon burning an NFT

    // Custom errors
    error InsufficientEther(); // Error for insufficient ether sent
    error MaxSupplyReached(); // Error when maximum supply of NFTs is reached
    error AlreadyMinted(); // Error when attempting to mint an already minted NFT
    error InvalidMerkleProof(); // Error for invalid Merkle proof

    /**
     * @dev Constructor to initialize the contract with the Merkle root hash and set default royalty.
     * @param _merkleRoot The Merkle root hash of the whitelist.
     */
    constructor(bytes32 _merkleRoot) ERC721("My NFT", "MNFT") Ownable(msg.sender) {
        merkleRoot = _merkleRoot; // Initialize Merkle root hash
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY); // Set default royalty for the owner
    }

    /**
     * @dev Checks if the contract supports the given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the given interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Mint function that allows addresses in the Merkle tree whitelist to mint at a discount.
     * @param _merkleProof The Merkle proof for the address.
     * @param _tokenId The ID of the token to mint.
     * @param index The index of the address in the Merkle tree.
     */
    function whitelistMint(bytes32[] memory _merkleProof, uint256 _tokenId, uint256 index) external payable {
        if (totalSupply >= MAX_SUPPLY) {
            revert MaxSupplyReached(); // Ensure maximum supply not reached
        }
        if (BitMaps.get(_bitmap, index)) {
            revert AlreadyMinted(); // Ensure address not already minted
        }

        if (msg.value < WHITELIST_MINT_PRICE) {
            revert InsufficientEther(); // Ensure correct amount of ether sent
        }

        // Verify the provided _merkleProof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, index))));

        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert InvalidMerkleProof(); // Ensure valid Merkle proof
        }

        // Mint the NFT
        BitMaps.set(_bitmap, index); // Mark address as minted
        totalSupply++; // Increment total supply
        _safeMint(msg.sender, _tokenId); // Mint the NFT

        emit Minted(msg.sender, _tokenId); // Emit Minted event
    }

    /**
     * @dev Mint function for regular minting.
     * @param _tokenId The ID of the token to mint.
     */
    function mint(uint256 _tokenId) external payable {
        if (totalSupply >= MAX_SUPPLY) {
            revert MaxSupplyReached(); // Ensure maximum supply not reached
        }

        if (msg.value < MINT_PRICE) {
            revert InsufficientEther(); // Ensure correct amount of ether sent
        }

        totalSupply++; // Increment total supply

        _safeMint(msg.sender, _tokenId); // Mint the NFT

        emit Minted(msg.sender, _tokenId); // Emit Minted event
    }

    /**
     * @dev Allows the owner to withdraw accumulated ether.
     */
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance); // Transfer ether to owner
    }
}
